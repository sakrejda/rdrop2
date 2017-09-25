
# These are the remaining tests after auth and upload.If the tests are getting
# to be more than 30 lines, split them off into a separate file. Execution order
# is is all of the `helper-*.R` files and then all of the `test-*.R` files

# All the file ops (move/copy/delete)
# drop_get, drop_upload
# ......................................
context("drop_get")


test_that("Drop_get work correctly", {
  skip_on_cran()
  download.file("http://media4.giphy.com/media/YaXcVXGvBQlEI/200.gif",
                destfile = "duck_rabbit-drop_get.gif")
  drop_upload("duck_rabbit-drop_get.gif")
  drop_get("duck_rabbit-drop_get.gif", overwrite = TRUE)
  expect_true("duck_rabbit-drop_get.gif" %in% dir())
  file.remove("duck_rabbit-drop_get.gif")
  drop_delete("duck_rabbit-drop_get.gif")
})

# drop_copy
# ......................................
test_that("Copying files works correctly", {
  skip_on_cran()
  file_name <- paste0(uuid::UUIDgenerate(), "-copy-", "d")
  write.csv(iris, file = file_name)
  drop_upload(file_name)
  drop_create("copy_test")
  # Try a duplicate create. This should fail
  expect_error(drop_create("copy_test"))
  drop_upload(file_name)
  drop_copy(file_name, paste0("/copy_test/", file_name))
  res <- drop_dir("copy_test")
  expect_identical(basename(file_name), basename(res$path_lower))
  drop_delete("copy_test")
  unlink(file_name)
  drop_delete(file_name)
})

# drop_move
# ......................................
test_that("Moving files works correctly", {
  skip_on_cran()
  file_name <- paste0(uuid::UUIDgenerate(), "-move-", "d")
  write.csv(iris, file = file_name)
  drop_upload(file_name)
  drop_create("move_test")
  drop_move(file_name, paste0("/move_test/", file_name))
  res <- drop_dir("move_test")
  # problem
  expect_identical(basename(file_name), basename(res$path_lower))
  # Now test that the file is there.
  # do a search for the path/file
  # the make sure it exists
  # ......................................
  drop_delete("/move_test")
  unlink(file_name)
})

# drop_shared
# ......................................
context("testing drop share")
test_that("Sharing a Dropbox resource works correctly", {
  skip_on_cran()
  file_name <- paste0(uuid::UUIDgenerate(), "-share", ".csv")
  write.csv(iris, file = file_name)
  drop_upload(file_name)
  res <- drop_share(file_name)
  expect_equal(length(res), 10)
  share_names <- sort(c(".tag", "url", "id", "name", "path_lower", "link_permissions",
                        "client_modified", "server_modified", "rev", "size"))
  res_names <- sort(names(res))
  expect_identical(share_names, res_names)
  unlink(file_name)
  drop_delete(file_name)
})



# drop_search
# ......................................

context("testing search")

test_that("Drop search works correctly", {

  skip_on_cran()

  folder_name <- paste0("test-drop_search-", uuid::UUIDgenerate())
  drop_create(folder_name)

  write.csv(mtcars, "mtcars.csv")
  drop_upload("mtcars.csv", path = folder_name)

  x <- drop_search("mt")

  expect_equal(x$matches[[1]]$metadata$name, "mtcars.csv")

  # A search with no query should fail
  expect_error(drop_search())

  #cleanup
  drop_delete(folder_name)
  unlink("mtcars.csv")
})


# drop_history

context("testing dropbox revisions")

test_that("Revisions are returned correctly", {
  skip_on_cran()

  write.csv(iris, file = "iris.csv")
  drop_upload("iris.csv")
  write.csv(iris[iris$Species == "setosa",], file = "iris.csv")
  drop_upload("iris.csv")
  x <- drop_history("iris.csv")
  expect_equal(ncol(x), 15)
  expect_is(x, "data.frame")
  drop_delete("/iris.csv")
  unlink("iris.csv")
})

# drop_exists

context("testing Dropbox exists")
test_that("We can verify that a file exists on Dropbox", {
  skip_on_cran()

  drop_create("existential_test")
  expect_true(drop_exists("existential_test"))
  expect_false(drop_exists(paste0(uuid::UUIDgenerate(), uuid::UUIDgenerate(), "d")))
  # Now test files inside subfolders
  write.csv(iris, file = "iris.csv")
  drop_upload("iris.csv", path = "existential_test")
  expect_true(drop_exists("existential_test/iris.csv"))
  drop_delete("existential_test")
  unlink("iris.csv")
})


# drop_media
context("Testing Media URLs")

test_that("Media URLs work correctly", {
  skip_on_cran()
  download.file("http://media4.giphy.com/media/YaXcVXGvBQlEI/200.gif",
                destfile = "duck_rabbit-media.gif")
  drop_upload("duck_rabbit-media.gif")
  media_url <- drop_media("duck_rabbit-media.gif")
  expect_match(media_url$link, "https://dl.dropboxusercontent.com")
  unlink("duck_rabbit-media.gif")
  drop_delete("duck_rabbit-media.gif")
})


context("Testing drop_read_csv")

test_that("Can read csv files directly from dropbox", {
  skip_on_cran()

  file_name <- paste0(uuid::UUIDgenerate(), "-drop_read-", ".csv")
  write.csv(iris, file = file_name)
  drop_upload(file_name)
  z <- drop_read_csv(file_name)
  expect_is(z, "data.frame")
  unlink(file_name)
  drop_delete(file_name)
})
# No stray files to this point

context("Drop delta works")

test_that("Drop delta works", {
  skip_on_cran()

  file_name <- paste0(uuid::UUIDgenerate(), "-drop_delta-", ".csv")
  write.csv(iris, file = file_name)
  z <- drop_delta(path_prefix = "/")
  expected_names <- c("has_more", "cursor", "entries", "reset")
  expect_identical(names(z), expected_names)
  unlink(file_name)
})

context("drop exists")

test_that("Drop exists works", {
  skip_on_cran()
  drop_create("existential_test")
  expect_true(drop_exists("existential_test"))
  drop_delete("existential_test")
})