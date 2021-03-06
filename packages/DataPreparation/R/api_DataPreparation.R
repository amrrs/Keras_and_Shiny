#'
#' Reads the file and converts it into grayscale pixel intensity tensor.
#'
#' @param image_fpath PNG image file path (28 x 28, grayscale).
#'
#' @return tensor with dimensions 28 x 28 x 1.
#'
#' @export
#'
loadAndPrepareImage <- function(image_fpath) {
    assert(file.exists(image_fpath), "Invalid image file path.")

    image <- image_load(image_fpath, grayscale = TRUE)
    image_array <- image_to_array(image)

    return(image_array)
}

#'
#' Reading consecutive files, converting to a pixel intensity tensor and appending them to a single tensor which eventually should contain all read numbers, one after another. Additionally, creating a vector with respective labels "0" to "9".
#'
#' @param data_path a path to the folder with data and the subfolder name (one of: "training", "testing")
#' @param subfolder_name "training" and "testing" subfolders should contain another level of subfolders, labelled 0-9 with the examples (28 x 28 grayscale PNG images) of respective handwritten digits
#'
#' @return a two-element list: 1) "data_tensor": a 4D tensor with dimensions [number_of_images x 28 x 28 x 1] containing pixel intensities of all numbers and 2) "labels": a character vector containing respective labels
#'
#' @export
#'
getAllImages <- function(data_path, subfolder_name) {
    assert(subfolder_name %in% c("training", "testing"),
           "subfolder name should be one of: 'training', 'testing'.")

    # initialize a matrix representing  all read images and a vector of labels
    data <- array(dim = c(0, 28, 28, 1))
    labels <- character(0)

    # a loop over all subfolders "0" to "9"
    for (i in 0:9) {
        number_folder_path <- file.path(data_path, subfolder_name, i)
        image_names <- list.files(number_folder_path, pattern = "*.png")

        n <- length(image_names)
        number_data <- array(dim = c(n, 28, 28, 1))
        number_labels <- rep(as.character(i), n)

        pkg_loginfo("Number of images with label %d: %d", i, n)

        # a loop over all files in a subfolder
        j <- 1
        for (image_name in image_names) {
            image_fpath <- file.path(number_folder_path, image_name)
            number_data[j, , , ] <- loadAndPrepareImage(image_fpath)

            if (j %% 100 == 0)
                pkg_loginfo("Processed %d out of %d images (label %d)...", j, n, i)

            j <- j + 1
        }

        data <- abind(data, number_data, along = 1)
        labels <- c(labels, number_labels)
    }

    return(list(data_tensor = data, labels = labels))
}

#'
#' Normalize intensities to the scale 0-1.
#'
#' @param data_tensor pixel intensities data tensor (values in 0-255)
#'
#' @return normalized pixel intensities data tensor (values in [0, 1])
#'
#' @export
#'
normalizePixelIntensities <- function(data_tensor) {
  data_tensor <- data_tensor / 255

  return(data_tensor)
}

#'
#' Convert a label vector into one-hot encoded label matrix.
#'
#' @param labels A character vector with labels.
#'
#' @return One-hot encoded label matrix.
#'
#' @export
#'
convertLabels <- function(labels) {
  labels <- to_categorical(labels, num_classes = 10)

  return(labels)
}

#'
#' Split input dataset (both data and labels) into training and validation subset using the provided fraction parameter to determine the proportion.
#'
#' @param data named list containing training/validation dataset ("$data") and labels ("$labels")
#' @param training_fraction a fraction of dataset to be used as training subset
#'
#' @return named list with training subset and labels and validation subset and labels
#'
#' @export
#'
splitDataset <- function(data, training_fraction = 0.75) {
    assert(training_fraction > 0 & training_fraction < 1, "training_fraction has to be between 0 and 1.")

    valid_fraction = 1 - training_fraction
    ind <- sample(2, size = dim(data$data)[1], replace = TRUE, prob = c(training_fraction, valid_fraction))

    train_data <- data$data[ind == 1, , , , drop = FALSE]
    valid_data <- data$data[ind == 2, , , , drop = FALSE]
    train_labels <- data$labels[ind == 1, ]
    valid_labels <- data$labels[ind == 2, ]

    return(list(
        data_tensor = list(train = train_data, valid = valid_data),
        labels = list(train = train_labels, valid = valid_labels)))
}
