# azd-ai ![Awesome Badge](https://awesome.re/badge-flat2.svg)

An `azd` template to deploy Tika and Litellm postgreSQL database.

To use this template, follow these steps using the [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview):

1. Log in to Azure Developer CLI. This is only required once per-install.

    ```bash
    azd auth login
    ```

2. Initialize this template using `azd init`:

    ```bash
    azd init --template ioitcloud/azd-ai
    ```

3. Use `azd up` to provision your Azure infrastructure and deploy the web application to Azure.

    ```bash
    azd up
    ```

4. `azd up` will prompt you to enter these additional secret and password parameters used to configure PostgreSQL:

    - `databaseAdminPassword`: The Admin password use to connect to the PostgreSQL database.

    Be sure to save these secrets and passwords to keep them safe.

5. Once the template has finished provisioning all resources, and Azure Container Apps has completed deploying the tika container _(this can take a minute or so after `azd up` completes to finish)_, you can access both the Swagger UI and UI for tika