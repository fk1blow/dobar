defmodule Dobar.Dialog.Species.Routes do
  use Dobar.Dialog.Species.Router

  specie :generic_dialog, to: Dobar.Dialog.GenericDialog
  specie :create_alarm, to: Dobar.Dialog.GenericDialog
  specie :change_field, to: Dobar.Dialog.ChangeFieldDialog
  specie :purge_change_fields, to: Dobar.Dialog.PurgeChangeFieldsDialog
end
