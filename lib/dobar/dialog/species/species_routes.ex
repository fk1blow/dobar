defmodule Dobar.Dialog.Species.Routes do
  use Dobar.Dialog.Species.Router

  specie :generic_dialog, to: Dobar.Dialog.GenericDialog
  specie :cancel_command, to: Dobar.Dialog.CancelCommandDialog
  specie :create_alarm, to: Dobar.Dialog.GenericDialog
  specie :change_field, to: Dobar.Dialog.ChangeFieldDialog
  specie :purge_change_fields, to: Dobar.Dialog.PurgeChangeFieldsDialog
  specie :switch_conversation, to: Dobar.Dialog.SwitchConversationDialog
  specie :confirmation, to: Dobar.Dialog.ConfirmationDialog
end
