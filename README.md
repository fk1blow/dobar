# Dobar

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: http://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix

## todos

- when a dialog that ends with a confirmation, how do i handle this kind of reaction?  
- add confidence validation at root dialog start
- fix validation for unknown intents - when starting a new topic and alternative dialog
- validate intention confidence validation when creating a new Dialog
- don't start new conversation if the intent already exists in the conversation chain
- see if taking the first item inside the `entities` list is ok(Topic :complete)
- don't let the "approvde" intention to be started(like cancel, change, etc)
- add a supervisor to the dialog species and make it the interface
- issues when using 'String.to_existing_atom` for undefined intention definition
