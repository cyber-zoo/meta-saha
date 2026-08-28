#include <cerrno>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <limits>
#include <unistd.h>
#include <vector>

#include <dnn/hb_dnn.h>

namespace {

constexpr char kDefaultModel[] =
    "/usr/share/saha-rdk-x5-bpu-smoke/himloco_go2_bayese_1x270.bin";
constexpr char kDefaultInput[] =
    "/usr/share/saha-rdk-x5-bpu-smoke/himloco_obs_history_000000.bin";
constexpr char kBpuModulePath[] = "/sys/module/bpu_hw_io_x5";
constexpr uint32_t kInputElements = 270;
constexpr uint32_t kOutputElements = 12;
constexpr size_t kInputBytes = kInputElements * sizeof(float);

void FreeTensors(std::vector<hbDNNTensor> *tensors) {
  for (hbDNNTensor &tensor : *tensors) {
    if (tensor.sysMem[0].virAddr != nullptr) {
      hbSysFreeMem(&tensor.sysMem[0]);
      tensor.sysMem[0] = {};
    }
  }
}

uint64_t Fnv1a(uint64_t hash, const uint8_t *data, uint32_t length) {
  for (uint32_t index = 0; index < length; ++index) {
    hash ^= data[index];
    hash *= UINT64_C(1099511628211);
  }
  return hash;
}

bool TensorElementCount(const hbDNNTensorProperties &properties,
                        uint32_t *element_count) {
  const hbDNNTensorShape &shape = properties.validShape;
  if (shape.numDimensions <= 0 ||
      shape.numDimensions > HB_DNN_TENSOR_MAX_DIMENSIONS) {
    return false;
  }

  uint64_t count = 1;
  for (int32_t index = 0; index < shape.numDimensions; ++index) {
    const int32_t dimension = shape.dimensionSize[index];
    if (dimension <= 0 ||
        count > std::numeric_limits<uint32_t>::max() /
                    static_cast<uint32_t>(dimension)) {
      return false;
    }
    count *= static_cast<uint32_t>(dimension);
  }
  *element_count = static_cast<uint32_t>(count);
  return true;
}

bool IsExpectedTensor(const char *actual_name, const char *expected_name,
                      const hbDNNTensorProperties &properties,
                      uint32_t expected_elements) {
  uint32_t element_count = 0;
  return actual_name != nullptr &&
         std::strcmp(actual_name, expected_name) == 0 &&
         properties.tensorType == HB_DNN_TENSOR_TYPE_F32 &&
         properties.quantiType == NONE &&
         properties.alignedByteSize > 0 &&
         TensorElementCount(properties, &element_count) &&
         element_count == expected_elements;
}

bool LoadObservation(const char *input_path, std::vector<float> *observation) {
  std::ifstream input(input_path, std::ios::binary);
  if (!input) {
    return false;
  }
  input.seekg(0, std::ios::end);
  if (input.tellg() != static_cast<std::streamoff>(kInputBytes)) {
    return false;
  }
  input.seekg(0, std::ios::beg);

  observation->resize(kInputElements);
  input.read(reinterpret_cast<char *>(observation->data()), kInputBytes);
  if (!input) {
    return false;
  }
  for (float value : *observation) {
    if (!std::isfinite(value)) {
      return false;
    }
  }
  return true;
}

bool HasFiniteActions(const hbDNNTensor &output) {
  if (output.sysMem[0].virAddr == nullptr ||
      output.sysMem[0].memSize < kOutputElements * sizeof(float)) {
    return false;
  }
  const float *actions =
      static_cast<const float *>(output.sysMem[0].virAddr);
  for (uint32_t index = 0; index < kOutputElements; ++index) {
    if (!std::isfinite(actions[index])) {
      return false;
    }
  }
  return true;
}

void PrintUsage(const char *program) {
  std::printf("Usage: %s [himloco-model.bin [obs-history.bin]]\n", program);
  std::printf("Runs the bundled official HIMLoco Go2 policy by default.\n");
}

}  // namespace

int main(int argc, char **argv) {
  if (argc > 3 || (argc == 2 && std::strcmp(argv[1], "--help") == 0)) {
    PrintUsage(argv[0]);
    return argc == 2 ? EXIT_SUCCESS : EXIT_FAILURE;
  }

  const char *model_path = argc >= 2 ? argv[1] : kDefaultModel;
  const char *input_path = argc >= 3 ? argv[2] : kDefaultInput;
  const char *model_files[] = {model_path};
  hbPackedDNNHandle_t packed_dnn_handle = nullptr;
  hbDNNHandle_t dnn_handle = nullptr;
  hbDNNTaskHandle_t task_handle = nullptr;
  hbDNNTensor *output_tensors = nullptr;
  const char **model_names = nullptr;
  const char *input_name = nullptr;
  const char *output_name = nullptr;
  int32_t model_count = 0;
  int32_t input_count = 0;
  int32_t output_count = 0;
  int32_t result = 0;
  const char *failure_stage = nullptr;
  int32_t failure_code = 0;
  std::vector<float> observation;
  std::vector<hbDNNTensor> inputs;
  std::vector<hbDNNTensor> outputs;
  uint64_t output_hash = UINT64_C(1469598103934665603);
  uint64_t output_bytes = 0;

  do {
    if (access(model_path, R_OK) != 0) {
      failure_stage = "model_access";
      failure_code = errno;
      break;
    }
    if (access(input_path, R_OK) != 0) {
      failure_stage = "input_access";
      failure_code = errno;
      break;
    }
    if (!LoadObservation(input_path, &observation)) {
      failure_stage = "input_data";
      failure_code = EINVAL;
      break;
    }

    result = hbDNNInitializeFromFiles(&packed_dnn_handle, model_files, 1);
    if (result != 0) {
      failure_stage = "model_load";
      failure_code = result;
      break;
    }

    result = hbDNNGetModelNameList(&model_names, &model_count, packed_dnn_handle);
    if (result != 0 || model_count != 1 || model_names == nullptr) {
      failure_stage = "model_enumerate";
      failure_code = result != 0 ? result : EBADMSG;
      break;
    }

    result = hbDNNGetModelHandle(&dnn_handle, packed_dnn_handle, model_names[0]);
    if (result != 0) {
      failure_stage = "model_handle";
      failure_code = result;
      break;
    }

    result = hbDNNGetInputCount(&input_count, dnn_handle);
    if (result != 0 || input_count != 1) {
      failure_stage = "input_count";
      failure_code = result != 0 ? result : EBADMSG;
      break;
    }

    result = hbDNNGetOutputCount(&output_count, dnn_handle);
    if (result != 0 || output_count != 1) {
      failure_stage = "output_count";
      failure_code = result != 0 ? result : EBADMSG;
      break;
    }

    hbDNNTensorProperties input_properties{};
    hbDNNTensorProperties output_properties{};
    result = hbDNNGetInputName(&input_name, dnn_handle, 0);
    if (result == 0) {
      result = hbDNNGetInputTensorProperties(&input_properties, dnn_handle, 0);
    }
    if (result != 0 ||
        !IsExpectedTensor(input_name, "obs_history", input_properties,
                          kInputElements) ||
        input_properties.alignedByteSize <
            static_cast<int32_t>(kInputBytes)) {
      failure_stage = "input_contract";
      failure_code = result != 0 ? result : EBADMSG;
      break;
    }

    result = hbDNNGetOutputName(&output_name, dnn_handle, 0);
    if (result == 0) {
      result = hbDNNGetOutputTensorProperties(&output_properties, dnn_handle, 0);
    }
    if (result != 0 ||
        !IsExpectedTensor(output_name, "actions", output_properties,
                          kOutputElements) ||
        output_properties.alignedByteSize <
            static_cast<int32_t>(kOutputElements * sizeof(float))) {
      failure_stage = "output_contract";
      failure_code = result != 0 ? result : EBADMSG;
      break;
    }

    inputs.assign(1, hbDNNTensor{});
    inputs[0].properties = input_properties;
    result = hbSysAllocCachedMem(
        &inputs[0].sysMem[0],
        static_cast<uint32_t>(input_properties.alignedByteSize));
    if (result != 0) {
      failure_stage = "input_allocate";
      failure_code = result;
      break;
    }
    std::memset(inputs[0].sysMem[0].virAddr, 0,
                static_cast<size_t>(input_properties.alignedByteSize));
    std::memcpy(inputs[0].sysMem[0].virAddr, observation.data(), kInputBytes);
    result = hbSysFlushMem(&inputs[0].sysMem[0], HB_SYS_MEM_CACHE_CLEAN);
    if (result != 0) {
      failure_stage = "input_flush";
      failure_code = result;
      break;
    }

    outputs.assign(1, hbDNNTensor{});
    outputs[0].properties = output_properties;
    result = hbSysAllocCachedMem(
        &outputs[0].sysMem[0],
        static_cast<uint32_t>(output_properties.alignedByteSize));
    if (result != 0) {
      failure_stage = "output_allocate";
      failure_code = result;
      break;
    }
    std::memset(outputs[0].sysMem[0].virAddr, 0,
                static_cast<size_t>(output_properties.alignedByteSize));
    result = hbSysFlushMem(&outputs[0].sysMem[0], HB_SYS_MEM_CACHE_CLEAN);
    if (result != 0) {
      failure_stage = "output_flush";
      failure_code = result;
      break;
    }

    hbDNNInferCtrlParam infer_ctrl{};
    HB_DNN_INITIALIZE_INFER_CTRL_PARAM(&infer_ctrl);
    output_tensors = outputs.data();
    result = hbDNNInfer(&task_handle, &output_tensors, inputs.data(), dnn_handle,
                        &infer_ctrl);
    if (result != 0) {
      failure_stage = "infer_submit";
      failure_code = result;
      break;
    }

    result = hbDNNWaitTaskDone(task_handle, 5000);
    if (result != 0) {
      failure_stage = "infer_wait";
      failure_code = result;
      break;
    }

    if (access(kBpuModulePath, F_OK) != 0) {
      failure_stage = "driver_module";
      failure_code = errno;
      break;
    }

    result = hbSysFlushMem(&outputs[0].sysMem[0],
                           HB_SYS_MEM_CACHE_INVALIDATE);
    if (result != 0) {
      failure_stage = "output_invalidate";
      failure_code = result;
      break;
    }
    if (!HasFiniteActions(outputs[0])) {
      failure_stage = "output_actions";
      failure_code = EBADMSG;
      break;
    }
    output_hash = Fnv1a(
        output_hash,
        static_cast<const uint8_t *>(outputs[0].sysMem[0].virAddr),
        outputs[0].sysMem[0].memSize);
    output_bytes = outputs[0].sysMem[0].memSize;
  } while (false);

  if (task_handle != nullptr) {
    hbDNNReleaseTask(task_handle);
  }
  FreeTensors(&outputs);
  FreeTensors(&inputs);
  if (packed_dnn_handle != nullptr) {
    hbDNNRelease(packed_dnn_handle);
  }

  if (failure_stage != nullptr) {
    std::fprintf(stderr, "BPU_SMOKE_FAIL stage=%s code=%d\n", failure_stage,
                 failure_code);
    return EXIT_FAILURE;
  }

  std::printf(
      "BPU_SMOKE_PASS algorithm=himloco-go2 model=%s input=%s runtime=%s "
      "inputs=%d outputs=%d actions=%u action_finite=1 output_bytes=%llu "
      "output_fnv1a64=%016llx driver=bpu_hw_io_x5\n",
      model_path, input_path, hbDNNGetVersion(), input_count, output_count,
      kOutputElements, static_cast<unsigned long long>(output_bytes),
      static_cast<unsigned long long>(output_hash));
  return EXIT_SUCCESS;
}
