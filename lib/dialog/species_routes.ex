defmodule Dobar.Dialog.SpeciesRoutes do
  use Dobar.Dialog.Router

  dialog :generic_dialog, to: Dobar.Dialog.GenericDialog
  # dialog :cancel_command, to: Dobar.Dialog.CancelCommandDialog
  dialog :create_alarm, to: Dobar.Dialog.GenericDialog
  dialog :change_field, to: Dobar.Dialog.ChangeFieldDialog
  dialog :purge_change_fields, to: Dobar.Dialog.PurgeChangeFieldsDialog
end
