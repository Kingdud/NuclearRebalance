data:extend{
  {
    type = "int-setting",
    name = "gc-asif-ratio",
    setting_type = "startup",
    minimum_value = 25,
    maximum_value = 1000,
    default_value = 25,
    order = "b",
  },
  {
    type = "int-setting",
    name = "rc-asif-ratio",
    setting_type = "startup",
    minimum_value = 25,
    maximum_value = 1000,
    default_value = 25,
    order = "c",
  },
  {
    type = "int-setting",
    name = "bc-asif-ratio",
    setting_type = "startup",
    minimum_value = 25,
    maximum_value = 1000,
    default_value = 25,
    order = "d",
  },
  {
    type = "int-setting",
    name = "lds-asif-ratio",
    setting_type = "startup",
    minimum_value = 25,
    maximum_value = 1000,
    default_value = 25,
    order = "e",
  },
  {
    type = "int-setting",
    name = "eng-asif-ratio",
    setting_type = "startup",
    minimum_value = 25,
    maximum_value = 1000,
    default_value = 25,
    order = "e",
  },
  {
    type = "int-setting",
    name = "spd-3-asif-ratio",
    setting_type = "startup",
    minimum_value = 10,
    maximum_value = 100,
    default_value = 10,
    order = "f",
  },
  {
    type = "int-setting",
    name = "prod-3-asif-ratio",
    setting_type = "startup",
    minimum_value = 10,
    maximum_value = 100,
    default_value = 10,
    order = "f",
  },
  {
    type = "int-setting",
    name = "pla-asif-ratio",
    setting_type = "startup",
    minimum_value = 10,
    maximum_value = 1000,
    default_value = 50,
    order = "g",
  },
  {
    type = "int-setting",
    name = "max-bld-size",
    setting_type = "startup",
    allowed_values = {0, 31,39,49,57,67,75,85,93,103,111,121,129,139,147,157,165,175,183,193,201,211,219,229,237,247,255,265,273,283,291,301,309,319,327,337,345,355,363,373,381,391,399,409,417,427,435,445,453,463,471,481,489,499,507,517,525,535,543,553,561,571,579,589,597,607,615,625,633,643,651,661,669,679,687,697,705,715,723,733,741,751,759,769,777,787,795,805,813,823,831,841,849,859,867,877,885,895,903,913,921,931,939,949,957,967,975,985,993},
	default_value = 0,
    order = "z",
  },
--  {
--    type = "int-setting",
--    name = "pg-asif-ratio",
--    setting_type = "startup",
--    minimum_value = 25,
--    maximum_value = 1000,
--    default_value = 25,
--    order = "b",
--  },
}