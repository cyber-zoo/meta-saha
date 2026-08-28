#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <vector>

#include <dnn/hb_dnn.h>

namespace {

constexpr char kDefaultModel[] =
    "/usr/share/saha-rdk-x5-bpu-smoke/mobilenetv1_224x224_nv12.bin";
constexpr char kBpuModulePath[] = "/sys/module/bpu_hw_io_x5";

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

void PrintUsage(const char *program) {
  std::printf("Usage: %s [model.bin]\n", program);
  std::printf("Runs one BPU inference; defaults to the bundled official MobileNetV1 model.\n");
}

}  // namespace

int main(int argc, char **argv) {
  if (argc > 2 || (argc == 2 && std::strcmp(argv[1], "--help") == 0)) {
    PrintUsage(argv[0]);
    return argc == 2 ? EXIT_SUCCESS : EXIT_FAILURE;
  }

  const char *model_path = argc == 2 ? argv[1] : kDefaultModel;
  const char *model_files[] = {model_path};
  hbPackedDNNHandle_t packed_dnn_handle = nullptr;
  hbDNNHandle_t dnn_handle = nullptr;
  hbDNNTaskHandle_t task_handle = nullptr;
  hbDNNTensor *output_tensors = nullptr;
  const char **model_names = nullptr;
  int32_t model_count = 0;
  int32_t input_count = 0;
  int32_t output_count = 0;
  int32_t result = 0;
  const char *failure_stage = nullptr;
  int32_t failure_code = 0;
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

    result = hbDNNInitializeFromFiles(&packed_dnn_handle, model_files, 1);
    if (result != 0) {
      failure_stage = "model_load";
      failure_code = result;
      break;
    }

    result = hbDNNGetModelNameList(&model_names, &model_count, packed_dnn_handle);
    if (result != 0 || model_count < 1 || model_names == nullptr) {
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
    if (result != 0 || input_count < 1) {
      failure_stage = "input_count";
      failure_code = result != 0 ? result : EBADMSG;
      break;
    }

    result = hbDNNGetOutputCount(&output_count, dnn_handle);
    if (result != 0 || output_count < 1) {
      failure_stage = "output_count";
      failure_code = result != 0 ? result : EBADMSG;
      break;
    }

    inputs.assign(static_cast<size_t>(input_count), hbDNNTensor{});
    for (int32_t index = 0; index < input_count; ++index) {
      result = hbDNNGetInputTensorProperties(&inputs[index].properties,
                                             dnn_handle, index);
      if (result != 0 || inputs[index].properties.alignedByteSize <= 0) {
        failure_stage = "input_properties";
        failure_code = result != 0 ? result : EBADMSG;
        break;
      }
      result = hbSysAllocCachedMem(
          &inputs[index].sysMem[0],
          static_cast<uint32_t>(inputs[index].properties.alignedByteSize));
      if (result != 0) {
        failure_stage = "input_allocate";
        failure_code = result;
        break;
      }
      std::memset(inputs[index].sysMem[0].virAddr, 0,
                  static_cast<size_t>(inputs[index].properties.alignedByteSize));
      result = hbSysFlushMem(&inputs[index].sysMem[0], HB_SYS_MEM_CACHE_CLEAN);
      if (result != 0) {
        failure_stage = "input_flush";
        failure_code = result;
        break;
      }
    }
    if (failure_stage != nullptr) {
      break;
    }

    outputs.assign(static_cast<size_t>(output_count), hbDNNTensor{});
    for (int32_t index = 0; index < output_count; ++index) {
      result = hbDNNGetOutputTensorProperties(&outputs[index].properties,
                                              dnn_handle, index);
      if (result != 0 || outputs[index].properties.alignedByteSize <= 0) {
        failure_stage = "output_properties";
        failure_code = result != 0 ? result : EBADMSG;
        break;
      }
      result = hbSysAllocCachedMem(
          &outputs[index].sysMem[0],
          static_cast<uint32_t>(outputs[index].properties.alignedByteSize));
      if (result != 0) {
        failure_stage = "output_allocate";
        failure_code = result;
        break;
      }
      std::memset(outputs[index].sysMem[0].virAddr, 0,
                  static_cast<size_t>(outputs[index].properties.alignedByteSize));
      result = hbSysFlushMem(&outputs[index].sysMem[0], HB_SYS_MEM_CACHE_CLEAN);
      if (result != 0) {
        failure_stage = "output_flush";
        failure_code = result;
        break;
      }
    }
    if (failure_stage != nullptr) {
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

    for (int32_t index = 0; index < output_count; ++index) {
      result = hbSysFlushMem(&outputs[index].sysMem[0],
                             HB_SYS_MEM_CACHE_INVALIDATE);
      if (result != 0) {
        failure_stage = "output_invalidate";
        failure_code = result;
        break;
      }
      output_hash = Fnv1a(
          output_hash,
          static_cast<const uint8_t *>(outputs[index].sysMem[0].virAddr),
          outputs[index].sysMem[0].memSize);
      output_bytes += outputs[index].sysMem[0].memSize;
    }
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
      "BPU_SMOKE_PASS model=%s runtime=%s inputs=%d outputs=%d output_bytes=%llu "
      "output_fnv1a64=%016llx driver=bpu_hw_io_x5\n",
      model_path, hbDNNGetVersion(), input_count, output_count,
      static_cast<unsigned long long>(output_bytes),
      static_cast<unsigned long long>(output_hash));
  return EXIT_SUCCESS;
}
