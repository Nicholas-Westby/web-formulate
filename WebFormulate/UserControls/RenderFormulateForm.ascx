<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="RenderFormulateForm.ascx.cs" Inherits="WebFormulate.UserControls.RenderFormulateForm" %>
<%@ Import Namespace="formulate.app.Layouts.Kinds.Basic" %>
<%@ Import Namespace="formulate.app.Validations.Kinds.Regex" %>
<%@ Import Namespace="formulate.app.Validations.Kinds.Mandatory" %>
<%@ Import Namespace="formulate.app.Forms.Fields.DropDown" %>
<%@ Import Namespace="formulate.app.Forms.Fields.RichText" %>
<%@ Import Namespace="formulate.app.Forms.Fields.Button" %>
<%@ Import Namespace="formulate.app.Forms.Fields.RadioButtonList" %>
<%@ Import Namespace="formulate.app.Forms.Fields.ExtendedRadioButtonList" %>
<%@ Import Namespace="formulate.app.Forms.Fields.CheckboxList" %>
<%@ Import Namespace="formulate.app.Forms.Fields.Header" %>
<%@ Import Namespace="formulate.core.Extensions" %>
<%@ Import Namespace="formulate.core.Types" %>

<script runat="server">
    private string GetAngularModel()
    {

        // Validate model.
        if (FormModel == null)
        {
            return null;
        }

        // Variables.
        var fields = FormModel.FormDefinition.Fields;
        var layout = FormModel.LayoutDefinition.Configuration as LayoutBasicConfiguration;


        // This view can only render basic layouts.
        if (layout == null)
        {
            return null;
        }


        // A function that returns a validation configuration.
        var getValidationConfig = new Func<ValidationDefinition, object>(x =>
        {
            if (x.ValidationType == typeof(ValidationRegex))
            {
                var config = x.Configuration as ValidationRegexConfiguration;
                return new
                {
                    message = config.Message,
                    pattern = config.Pattern
                };
            }
            else if (x.ValidationType == typeof(ValidationMandatory))
            {
                var config = x.Configuration as ValidationMandatoryConfiguration;
                return new
                {
                    message = config.Message
                };
            }
            return new { };
        });


        // A function that returns a field configuration.
        var getFieldConfig = new Func<FieldDefinition, object>(x =>
        {
            if (x.FieldType == typeof(DropDownField))
            {
                var config = x.Configuration as DropDownConfiguration;
                return new
                {
                    items = config.Items.Select(y => new
                    {
                        value = y.Value,
                        label = y.Label,
                        selected = y.Selected
                    }).ToArray()
                };
            }
            else if (x.FieldType == typeof(RichTextField))
            {
                var config = x.Configuration as RichTextConfiguration;
                return new
                {
                    text = config.Text
                };
            }
            else if (x.FieldType == typeof(HeaderField))
            {
                var config = x.Configuration as HeaderConfiguration;
                return new
                {
                    text = config.Text
                };
            }
            else if (x.FieldType == typeof(formulate.app.Forms.Fields.Button.ButtonField))
            {
                var config = x.Configuration as ButtonConfiguration;
                return new
                {
                    buttonKind = config.ButtonKind
                };
            }
            else if (x.FieldType == typeof(RadioButtonListField))
            {
                var config = x.Configuration as RadioButtonListConfiguration;
                return new
                {
                    orientation = config.Orientation,
                    items = config.Items.Select(y => new
                    {
                        value = y.Value,
                        label = y.Label,
                        selected = y.Selected
                    }).ToArray()
                };
            }
            else if (x.FieldType == typeof(ExtendedRadioButtonListField))
            {
                var config = x.Configuration as ExtendedRadioButtonListConfiguration;
                return new
                {
                    items = config.Items.Select(y => new
                    {
                        primary = y.Primary,
                        secondary = y.Secondary,
                        selected = y.Selected
                    }).ToArray()
                };
            }
            else if (x.FieldType == typeof(CheckboxListField))
            {
                var config = x.Configuration as CheckboxListConfiguration;
                return new
                {
                    items = config.Items.Select(y => new
                    {
                        value = y.Value,
                        label = y.Label,
                        selected = y.Selected
                    }).ToArray()
                };
            }
            return new { };
        });


        // Structure fields as an anonymous object suitable for serialization to JSON.
        var fieldsData = fields.Select(x => new
        {
            // The alias can be used to attach custom styles.
            alias = x.Alias,
            // The label can be used to instruct the user what data to enter.
            label = x.Label ?? x.Name,
            // The ID can be submitted to the server to uniquely identify the field.
            id = x.Id.ToString("N"),
            // The random ID can be used to uniquely identify the field on the page.
            // Note that this random ID is regenerated on each page render.
            randomId = Guid.NewGuid().ToString("N"),
            // This field type (e.g., "text", "checkbox") can be used to figure out how to render a field.
            fieldType = x.FieldType.Name.ConvertFieldTypeToAngularType(),
            // The validations can be used to validate that the data is of the expected format.
            validations = x.Validations.Select(y => new
            {
                id = y.Id.ToString("N"),
                alias = y.Alias,
                validationType = y.ValidationType.Name.ConvertValidationTypeToAngularType(),
                // The validation configuration stores parameters particular to a validation instance (e.g., a regex pattern).
                configuration = getValidationConfig(y)
            }).ToArray(),
            // The field configuration stores parameters particular to a field (e.g., a list of items).
            configuration = getFieldConfig(x),
            // The initial value comes from the query string based on the field alias.
            initialValue = string.IsNullOrWhiteSpace(x.Alias)
                ? null
                : Request.QueryString[x.Alias]
        }).ToArray();


        // Structure layout as an anonymous object suitable for serialization to JSON.
        var rowsData = layout.Rows.Select(x => new
        {
            cells = x.Cells.Select(y => new
            {
                columns = y.ColumnSpan,
                fields = y.Fields.Select(z => new
                {
                    id = z.FieldId.ToString("N")
                }).ToArray()
            }).ToArray()
        }).ToArray();


        // Convert to a JSON string that can be consumed by Angular.
        var angularModel = System.Web.Helpers.Json.Encode(new
        {
            data = new
            {
                // The name of the form can be use for analytics.
                name = FormModel.FormDefinition.Name,
                // The form alias can be used for custom styles.
                alias = FormModel.FormDefinition.Alias,
                // The random ID can be used to uniquely identify the form on the page.
                // Note that this random ID is regenerated on each page render.
                randomId = Guid.NewGuid().ToString("N"),
                // The fields in this form.
                fields = fieldsData,
                // The rows that define the form layout.
                rows = rowsData,
                payload = new
                {
                    FormId = FormModel.FormDefinition.FormId.ToString("N"),
                    PageId = FormModel.PageId
                },
                url = "/umbraco/formulate/submissions/submit"
            }
        });

        // Return serialized JSON to be passed to the Angular directive.
        return angularModel;

    }
</script>

<formulate-json-source source="<%: GetAngularModel() %>">
    <formulate-responsive-form form-data="::ctrl.data">
    </formulate-responsive-form>
</formulate-json-source>