return {
  no_consumer = true,
  fields = {
    username_field = { type = "string", required = true, default = "email" },
    create_consumer = { type = "boolean", required = true, default = false }
  }
}
