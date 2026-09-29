# This file is managed by the 'files-melty-ai' file bundle and updated automatically when `meltano upgrade` is run.
# To prevent any manual changes from being overwritten, remove the file bundle from `meltano.yml` or disable automatic updates:
#     meltano config --plugin-type=files files-melty-ai set _update .claude/meltano_knowledge_base/meltano_cloud/dataml-datastoreml.md false

# DatastoreML

Reference for the data store definition file (`datastores/*.yml`) that defines destinations for data loaded into a Meltano Cloud workspace.

## Overview

Datastores define a destination for data loaded into a workspace (`/reference/cloud/api/resources/workspaces`) by pipelines (`/reference/cloud/api/resources/pipelines`). The default datastore for a workspace is called Warehouse, and it is its own PostgreSQL database provisioned by Meltano Cloud, but this can be changed at any time to another datastore with your own credentials (see the supported data plugins of type `LOADER`: `/reference/cloud/api/resources/dataplugins`).

Datastore definitions are stored in YAML file format.

### Example: `datastores/Snowflake.yml`

```yaml
version: datastores/v0.1
data_plugin: loaders/target-snowflake--meltanolabs
properties:
  max-threads: -1
```

### Key Information

| Path | JSON Type | Description |
|---|---|---|
| `version` | `string` | The version identifies this artifact type. |
| `data_plugin` | `string` | The fully-qualified name of a data plugin supported for JDBC configuration. |
| `properties` | `object` | A map of properties, with the setting name as the key and the value e.g. `setting=value`, that configures the environment when used in a pipeline. |

---

## Further Reading

- Datastores API resource: `/reference/cloud/api/resources/datastores`
