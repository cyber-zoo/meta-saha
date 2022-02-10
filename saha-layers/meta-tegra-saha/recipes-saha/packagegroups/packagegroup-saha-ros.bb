SUMMARY = "Packagegroup for ROS software stack"
DESCRIPTION = "${SUMMARY}"

# ROS_SUPERFLORE_GENERATED_ARCH_SPECIFIC_* variables are MACHINE specific
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup
inherit ros_distro_${ROS_DISTRO}
# inherit ${ROS_DISTRO_TYPE}_image
# inherit ros_superflore_generated

LICENSE="Apache-2.0"
PACKAGES = "${PN}"

# ROS_BUILD_DEPENDS = ""

# ROS_BUILDTOOL_DEPENDS = " \
#    ament-cmake-native \
# "

# ROS_EXPORT_DEPENDS = ""

# ROS_BUILDTOOL_EXPORT_DEPENDS = ""

ROS_EXEC_DEPENDS = " \
    action_msgs \
    actionlib_msgs \
    bag_recorder_nodes \
    builtin_interfaces \
    class_loader \
    common_interfaces \
    composition_interfaces \
    console_bridge_vendor \
    diagnostic_msgs \
    eigen3_cmake_module \
    examples_tf2_py \
    fastcdr \
    fastrtps \
    fastrtps_cmake_module \
    foonathan_memory_vendor \
    geometry2 \
    geometry_msgs \
    kdl_parser \
    launch \
    launch_ros \
    launch_testing \
    launch_testing_ament_cmake \
    launch_testing_ros \
    launch_xml \
    launch_yaml \
    libcurl_vendor \
    libstatistics_collector \
    libyaml_vendor \
    lifecycle_msgs \
    message_filters \
    mimick_vendor \
    nav_msgs \
    orocos_kdl \
    osrf_pycommon \
    osrf_testing_tools_cpp \
    performance_test_fixture \
    pluginlib \
    pybind11_vendor \
    python_cmake_module \
    rcl \
    rcl_action \
    rcl_interfaces \
    rcl_lifecycle \
    rcl_logging_interface \
    rcl_logging_noop \
    rcl_logging_spdlog \
    rcl_yaml_param_parser \
    rclcpp \
    rclcpp_action \
    rclcpp_components \
    rclcpp_lifecycle \
    rclpy \
    rcpputils \
    rcutils \
    resource_retriever \
    rmw \
    rmw_dds_common \
    rmw_fastrtps_cpp \
    rmw_fastrtps_dynamic_cpp \
    rmw_fastrtps_shared_cpp \
    rmw_implementation \
    rmw_implementation_cmake \
    ros2action \
    ros2bag \
    ros2cli \
    ros2cli_common_extensions \
    ros2cli_test_interfaces \
    ros2component \
    ros2doctor \
    ros2interface \
    ros2launch \
    ros2lifecycle \
    ros2lifecycle_test_fixtures \
    ros2multicast \
    ros2node \
    ros2param \
    ros2run \
    ros2service \
    ros2test \
    ros2topic \
    ros2trace \
    ros_environment \
    ros_testing \
    rosbag2 \
    rosbag2_compression \
    rosbag2_compression_zstd \
    rosbag2_cpp \
    rosbag2_interfaces \
    rosbag2_performance_benchmarking \
    rosbag2_py \
    rosbag2_storage \
    rosbag2_storage_default_plugins \
    rosbag2_test_common \
    rosbag2_tests \
    rosbag2_transport \
    rosgraph_msgs \
    rosidl_adapter \
    rosidl_cli \
    rosidl_cmake \
    rosidl_default_generators \
    rosidl_default_runtime \
    rosidl_generator_c \
    rosidl_generator_cpp \
    rosidl_generator_dds_idl \
    rosidl_generator_py \
    rosidl_parser \
    rosidl_runtime_c \
    rosidl_runtime_cpp \
    rosidl_runtime_py \
    rosidl_typesupport_c \
    rosidl_typesupport_cpp \
    rosidl_typesupport_fastrtps_c \
    rosidl_typesupport_fastrtps_cpp \
    rosidl_typesupport_interface \
    rosidl_typesupport_introspection_c \
    rosidl_typesupport_introspection_cpp \
    rpyutils \
    rttest \
    sensor_msgs \
    sensor_msgs_py \
    shape_msgs \
    shared_queues_vendor \
    spdlog_vendor \
    sqlite3_vendor \
    sros2 \
    sros2_cmake \
    statistics_msgs \
    std_msgs \
    std_srvs \
    stereo_msgs \
    test_interface_files \
    test_launch_ros \
    test_launch_testing \
    test_msgs \
    test_osrf_testing_tools_cpp \
    test_rmw_implementation \
    test_tf2 \
    tf2 \
    tf2_bullet \
    tf2_eigen \
    tf2_eigen_kdl \
    tf2_geometry_msgs \
    tf2_kdl \
    tf2_msgs \
    tf2_py \
    tf2_ros \
    tf2_ros_py \
    tf2_sensor_msgs \
    tf2_tools \
    tinyxml2_vendor \
    tlsf \
    tlsf_cpp \
    tracetools \
    tracetools_launch \
    tracetools_read \
    tracetools_test \
    tracetools_trace \
    trajectory_msgs \
    unique_identifier_msgs \
    urdf \
    urdf_parser_plugin \
    urdfdom \
    urdfdom_headers \
    visualization_msgs \
    yaml_cpp_vendor \
    zstd_vendor \
"

RDEPENDS:${PN} += "${ROS_EXEC_DEPENDS}"
