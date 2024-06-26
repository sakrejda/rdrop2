




#'Uploads a file to Dropbox.
#'
#'This function will allow you to write files of any size to Dropbox(even ones
#'that cannot be read into memory) by uploading them in chunks.
#'
#'@param file Relative path to local file.
#'@param path The relative path on Dropbox where the file should get uploaded.
#'@param mode - "add" - will not overwrite an existing file in case of a
#'  conflict. With this mode, when a a duplicate file.txt is uploaded, it  will
#'  become file (2).txt. - "overwrite" will always overwrite a file -
#'@param autorename This logical determines what happens when there is a
#'  conflict. If true, the file being uploaded will be automatically renamed to
#'  avoid the conflict. (For example, test.txt might be automatically renamed to
#'  test (1).txt.) The new name can be obtained from the returned metadata. If
#'  false, the call will fail with a 409 (Conflict) response code. The default is `TRUE`
#'@param mute Set to FALSE to prevent a notification trigger on the desktop and
#'  mobile apps
#' @references \href{https://www.dropbox.com/developers/documentation/http/documentation#files-upload}{API documentation}
#'@template verbose
#'@template token
#'@export
#' @examples \dontrun{
#' write.csv(mtcars, file = "mtt.csv")
#' drop_upload("mtt.csv")
#'}
drop_upload <- function(file,
                        path = NULL,
                        mode = "overwrite",
                        autorename = TRUE,
                        mute = FALSE,
                        verbose = FALSE,
                        dtoken = get_dropbox_token(),
                        root_namespace_id = drop_root_namespace_id()
) {
  put_url <- "https://content.dropboxapi.com/2/files/upload"
  put_session_url <- "https://content.dropboxapi.com/2/files/upload_session"

  assertthat::assert_that(file.exists(file))
  standard_modes <- c("overwrite", "add", "update")
  assertthat::assert_that(mode %in% standard_modes)

  file_size = file.size(file)
  if (file_size < 140 * 10^6) {
    req <- httr::POST(
      url = put_url,
      httr::config(token = dtoken),
      httr::add_headers(
        "Dropbox-API-Path-Root" = paste0(
          "{\".tag\": \"root\", \"root\": \"", root_namespace_id, "\"}"),      
        "Dropbox-API-Arg" = jsonlite::toJSON(list(path = path,
          mode = mode, autorename = autorename, mute = mute),
          auto_unbox = TRUE)
      ),
      body = httr::upload_file(file, type = "application/octet-stream")
      # application/octet-stream is to save to a file to disk and not worry about
      # what application/function might handle it. This lets another application
      # figure out how to read it. So for this purpose we're totally ok.
    )
    httr::stop_for_status(req)
    response <- httr::content(req)

    if (verbose) {
      pretty_lists(response)
      invisible(response)
    } else {
      message(
        sprintf(
          'File %s uploaded as %s successfully at %s',
          file,
          response$path_display,
          response$server_modified
        )
      )
      invisible(response)
    }
  } else {
    file_handle = file(file, raw = TRUE, open = 'rb')
    chunk = readBin(con = file_handle, what = 'raw', n = 140 * 10^6)
    chunk_index = 1
    req = httr::POST(
      url = paste(put_session_url, "start", sep = '/'),
      httr::config(token = dtoken),
      httr::add_headers(
        "Dropbox-API-Path-Root" = paste0(
          "{\".tag\": \"root\", \"root\": \"", root_namespace_id, "\"}"),
        "Dropbox-API-Arg" = jsonlite::toJSON(
          list(
            close = FALSE
          ),
          auto_unbox = TRUE),
        "Content-Type" = "application/octet-stream"
      ),
      body = chunk
    )

    httr::stop_for_status(req)
    response <- httr::content(req)
#    session_id = strsplit(response$session_id, ':')[[1]][2]
    session_id = response$session_id
    
    message(
      sprintf(
        'File %s upload session started as %s successfully at %s',
        file,
        response$path_display,
        response$server_modified
      )
    )

    while(TRUE) {
      chunk = readBin(con = file_handle, what = 'raw', n = 140 * 10^6)
      if (length(chunk) > 0) {
        chunk_index = chunk_index + 1
        req = httr::POST(
          url = paste(put_session_url, "append_v2", sep = '/'),
          httr::config(token = dtoken),
          httr::add_headers(
            "Dropbox-API-Path-Root" = paste0(
              "{\".tag\": \"root\", \"root\": \"", root_namespace_id, "\"}"),
            "Dropbox-API-Arg" = jsonlite::toJSON(
              list(
                close = FALSE,
                cursor = list(
                  offset = (chunk_index - 1) * 140 * 10^6,
                  session_id = session_id
                )
              ),
              auto_unbox = TRUE),
            "Content-Type" = "application/octet-stream"
          ),
          body = chunk
        )
           
        httr::stop_for_status(req)
        response <- httr::content(req)

        message(
          sprintf(
            'File %s uploaded as %s successfully at %s',
            file,
            response$path_display,
            response$server_modified
          )
        )
        last_chunk_length = length(chunk)
      } else {
        req = httr::POST(
          url = paste(put_session_url, "finish", sep = '/'),
          httr::config(token = dtoken),
          httr::add_headers(
            "Dropbox-API-Path-Root" = paste0(
              "{\".tag\": \"root\", \"root\": \"", root_namespace_id, "\"}"),
            "Dropbox-API-Arg" = jsonlite::toJSON(
              list(
                commit = list(
                  autorename = autorename,
                  mode = mode,
                  mute = mute,
                  path = path
                ),
                cursor = list(
                  offset = (chunk_index - 1) * 140 * 10^6 + last_chunk_length,
                  session_id = session_id
                )
              ),
              auto_unbox = TRUE),
            "Content-Type" = "application/octet-stream"
          ),
          body = ""
        )

           
        httr::stop_for_status(req)
        response <- httr::content(req)

        close(file_handle);         
        message(
          sprintf(
            'File %s uploaded chunk %s as %s successfully at %s',
            file,
            chunk_index,
            response$path_display,
            response$server_modified
          )
       )
       break
      }
    }
  }

}
