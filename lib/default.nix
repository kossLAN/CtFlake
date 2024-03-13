{ inputs
, outputs
, stateVersion
, ...
}:
let
  helpers = import ./helpers { inherit inputs outputs stateVersion; };
in
{
  inherit (helpers) mkHost mkLxcImage forAllSystems;
}
