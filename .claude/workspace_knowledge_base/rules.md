# Workspace rules

- **Pipeline settings live on the pipeline.** Put source/destination settings in the pipeline YAML's `properties` (`<data-component>.<setting>`), not in `meltano.yml` `config`.
- **Use default plugins; don't create inherited per-pipeline plugins** (e.g. `tap-x-<client>`) unless there's a concrete need. One plugin, configured per pipeline.
- **Pipeline YAML shape:** a `script:` running `meltano run <tap> <target> --state-id-suffix <pipeline-name>` (not `actions:`), single-line JSON for array/object properties, an explicit `<tap>._select`, and `<datastore>.add_record_metadata: true`.
