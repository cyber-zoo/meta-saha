# RDKOS 3.5.0's vendor 6.1.83 kernel has a backported module tracepoint
# layout that is incompatible with Wrynose lttng-modules 2.14.4.  The normal
# lttng-tools userspace package remains usable by ROS 2; disable only its
# optional ptest subpackage, which is what pulls that external kernel module.
PTEST_ENABLED:pn-lttng-tools = "0"
