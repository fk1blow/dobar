defmodule Dobar.Dialog.SpeciesRoutes do
  use Dobar.Dialog.Router

  dialog :generic_dialog, to: Dobar.Dialog.GenericDialog

  dialog :cancel_command, to: Dobar.Dialog.CancelCommand

  dialog :create_alarm, to: Dobar.Dialog.GenericDialog

  IO.inspect @dialogs
end
