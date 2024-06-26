#' Download a file from Dropbox to disk.
#'
#' @param path path to a file in Dropbox
#' @param local_path path to save file to. If NULL (the default), saves file to working directory with same name. If not null, but a valid folder, file will be saved in this folder with same basename as path. If not null and not a folder, file will be saved to this path exactly.
#' @param overwrite If TRUE, overwrite local file. Defaults to FALSE
#' @param progress If TRUE, show a progress bar for large file downloads. Defaults to TRUE in interactive sessions, otherwise FALSE.
#' @param verbose if TRUE, emit message giving location and size of the newly downloaded file. Defaults to TRUE in interactive sessions, otherwise FALSE.
#' @references \href{https://www.dropbox.com/developers/documentation/http/documentation#files-download}{API documentation}
#' @template token
#'
#' @return TRUE if successful; error thrown otherwise.
#'
#' @examples \dontrun{
#'
#'   # download a file to the current working directory
#'   drop_get("dataset.zip")
#'
#'   # download again, overwriting previous result
#'   drop_get("dataset.zip", overwrite = TRUE)
#'
#'   # download to a different path, keeping file name constant
#'   # will download to "some/other/place/dataset.zip"
#'   drop_get("dataset.zip", local_path = "some/other/place/")
#'
#'   # download to to a different path, changing filename
#'   drop_get("dataset.zip", local_path = "some/other/place/not_a_dataset.zip")
#' }
#'
#' @export
drop_download <- function(
  path,
  local_path = NULL,
  overwrite = FALSE,
  progress = interactive(),
  verbose = interactive(),
  dtoken = get_dropbox_token(),
  root_namespace_id = drop_root_namespace_id()
) {

  # if no local path given, download it to working directory
  # if path given is folder, append filename to it
  if (is.null(local_path)) {
    local_path = basename(path)
  } else if (dir.exists(local_path)) {
    local_path <- file.path(local_path, basename(path))
  }

  url <- "https://content.dropboxapi.com/2/files/download"

  req <- httr::POST(
    url = url,
    httr::config(token = dtoken),
    httr::add_headers(
      "Dropbox-API-Path-Root" = paste0(
        "{\".tag\": \"root\", \"root\": \"", root_namespace_id, "\"}"),      
      "Dropbox-API-Arg" = jsonlite::toJSON(
        list(
          path = path
        ),
        auto_unbox = TRUE)
    ),
    if (progress) httr::progress(),
    httr::write_disk(local_path, overwrite)
  )

  httr::stop_for_status(req)

  # print message in verbose mode
  if (verbose) {

    size <- file.size(local_path)
    class(size) <- "object_size"

    message(sprintf(
      "Downloaded %s to %s: %s on disk",
      path,
      local_path,
      format(size, units = "auto")
    ))
  }

  # must have been successful
  TRUE
}


#' Downloads a file from Dropbox
#'
#' @template path
#' @param  local_file The name of the local copy. Leave this blank if you're fine with the original name.
#' @param overwrite Default is \code{FALSE} but can be set to \code{TRUE}.
#' @param progress Progress bars are turned off by default. Set to \code{TRUE} ot turn this on. Progress is only reported when file sizes are known. Otherwise just bytes downloaded.
#' @template token
#' @template verbose
#'
#' @examples \dontrun{
#'   drop_get(path = 'dataset.zip', local_file = "~/Desktop")
#'   # To overwrite the existing file
#'   drop_get(path = 'dataset.zip', overwrite = TRUE)
#' }
#'
#' @export
drop_get <- function(
  path = NULL,
  local_file = NULL,
  overwrite = FALSE,
  verbose = FALSE,
  progress = FALSE,
  dtoken = get_dropbox_token()
) {

  .Deprecated("drop_download")

  #assertive::assert_is_not_null(path)
  assertthat::assert_that(!is.null(path))

  if (drop_exists(path, dtoken = dtoken)) {
    filename <- ifelse(is.null(local_file), basename(path), local_file)

    drop_download(path, filename, overwrite, progress, verbose, dtoken)

    if (!verbose) {
      # prints file sizes in kb but this could also be pretty printed
      message(sprintf("\n %s on disk %s KB", filename, file.size(filename)/1000))
      TRUE
    } else {
      drop_get_metadata(path)
    }
  } else {
    message("File not found on Dropbox \n")
    FALSE
  }
}
