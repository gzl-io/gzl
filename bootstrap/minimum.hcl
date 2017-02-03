# defaults to local source
# defaults to local resource
pipe {
  # checkout not needed
  clean = "make clean"
  build = "make all"
  test = "make test"
  deploy = "make deploy"
}
