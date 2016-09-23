Dobar - Conversation capability
===============================

Dobar is a bot that has many capabilities to respond when given an intention.
It will understand predefined topics within a conversation and react with 
a response, through its interface(and adapters).

## Interface

_and more possible ways to interact, through different adapters/interfaces_

Dobar's interface is how user interacts with it, how it gives input or how it 
receives it. It is the only way for the outside world, to interact with Dobar,
no matter if there are conversations or not!

#### Interface Adapters

Adapters are what they are - adapt an api to dobar's conversation and provide the way to interact and dialog with it.

Adapters default:
  1. console or terminal adapter
  2. another adapter....

## Conversation definition

tbd

## Dialog and Dialog species

tbd

## Topics

tbd

## Capabilities

_are slots that can react to input - reactive or proactive - or that have to be 
filled - inert or alert attribute_

tbd

Todos
-----

- after `{:error, :purge_nomatches}` the dialog doesn't work anymore
- when a dialog that ends with a confirmation, how do i handle this kind of reaction?  
- add confidence validation at root dialog start
- fix validation for unknown intents - when starting a new topic and alternative dialog
- validate intention confidence validation when creating a new Dialog
- don't start new conversation if the intent already exists in the conversation chain
- see if taking the first item inside the `entities` list is ok(Topic :complete)
- don't let the "approvde" intention to be started(like cancel, change, etc)
- add a supervisor to the dialog species and make it the interface
- issues when using 'String.to_existing_atom` for undefined intention definition
- dialog errors if the "purge_change_fields" intent doesn't contain the ":field_type" entity
- make the `Conversation.Definition` fill all the available fields ("inert", "prefill", etc)
