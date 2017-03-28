# Types of selinux enforcement
type Selinux::State = Variant[
  Boolean,
  Enum[
    'enforcing',
    'permissive',
    'disabled'
  ]
]
