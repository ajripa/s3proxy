# Get a timestamp. It is used by docker to tag the image and the provisioners

locals {
    timestamp_raw = "${timestamp()}"
    timestamp= "${replace("${local.timestamp_raw}", "/[-| |T|Z|:]/", "")}"
}