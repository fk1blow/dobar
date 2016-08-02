defmodule Dobar.Dialog.SpeciesRoutes do
  use Dobar.Dialog.Router

  dialog :generic_dialog, to: Dobar.Dialog.GenericDialog

  dialog :cancel_command, to: Dobar.Dialog.CancelCommand

  IO.inspect @dialogs
end
