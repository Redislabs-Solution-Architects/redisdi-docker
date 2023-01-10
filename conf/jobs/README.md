# Data Transformation Jobs

This directory (`jobs`) should contain YAML files that describe the jobs that should be used.

More information and reference documentation is available [here](https://redis-data-integration.docs.dev.redislabs.com/data-transformation/data-transformation-pipeline.html).

## Example

This example shows how to rename a certain field (`fname` to `first_name`) in a given table (`emp`) using the `rename_field` block.
It also demonstrates how to set the key of this record instead of relying on the default logic.

A job can contain a series of steps to accomplish different tasks.

redislabs.dbo.emp.yaml

```yaml
source:
  server_name: redislabs
  schema: dbo
  table: emp
transform:
  - uses: rename_field
    with:
      from_field: fname
      to_field: first_name
key:
  expression: concat(['emp:fname:',fname,':lname:',lname])
  language: jmespath
```
