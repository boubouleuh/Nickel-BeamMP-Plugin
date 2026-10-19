Fields = {}

local FieldTypes = {
    INTEGER = "INTEGER",
    BIGINT = "BIGINT",
    DECIMAL = "DECIMAL",
    FLOAT = "FLOAT",
    STRING = "STRING",
    TEXT = "TEXT",
    BOOLEAN = "BOOLEAN",
    DATE = "DATE",
    DATETIME = "DATETIME",
    BINARY = "BINARY",
    JSON = "JSON",
    UUID = "UUID"
}

local function CreateField(field_type, name)
    local default_length = nil
    if field_type == FieldTypes.STRING then
        default_length = 255
    elseif field_type == FieldTypes.UUID then
        default_length = 36
    end
    ---@class Field
    local field = {
        type = field_type,
        name = name,
        max_length = default_length,
        decimal_precision = nil,
        not_null = false,
        primary_key = false,
        auto_increment = false,
        unique = false,
        foreign_key = nil,
        default = nil
    }

    function field:Scale(total, decimals)
        if self.type ~= FieldTypes.DECIMAL and self.type ~= FieldTypes.FLOAT then
            error("Scale() is only valid for DECIMAL and FLOAT fields")
        end
        if type(total) ~= "number" or type(decimals) ~= "number" or total < 1 or decimals < 0 or decimals > total then
            error("Scale() requires valid total and decimal values")
        end
        self.decimal_precision = { total = total, decimals = decimals }
        return self
    end

    function field:ForeignKey(tbl, col, options)
        if type(tbl) ~= "string" or type(col) ~= "string" then
            error("ForeignKey() requires a table and column name")
        end
        self.foreign_key = {
            table = tbl,
            column = col,
            on_delete = "CASCADE",
            on_update = "CASCADE"
        }
        if type(options) == "string" then
            self.foreign_key.on_delete = options
        elseif type(options) == "table" then
            self.foreign_key.on_delete = options.on_delete or "CASCADE"
            self.foreign_key.on_update = options.on_update or "CASCADE"
        end
        return self
    end

    function field:PrimaryKey()
        self.primary_key = true
        self.not_null = true
        return self
    end

    function field:MaxLength(length)
        if type(length) ~= "number" or length < 1 or length ~= math.floor(length) then
            error("MaxLength() requires a positive integer")
        end
        self.max_length = length
        return self
    end

    function field:Nullable()
        if self.primary_key then error("A primary key cannot be nullable") end
        self.not_null = false
        return self
    end

    function field:NotNull()
        self.not_null = true
        return self
    end

    function field:Unique()
        self.unique = true
        return self
    end

    function field:Default(value)
        self.default = value
        return self
    end

    function field:AutoIncrement()
        if self.type ~= FieldTypes.INTEGER and self.type ~= FieldTypes.BIGINT then
            error("AutoIncrement() requires an INTEGER or BIGINT field")
        end
        self.auto_increment = true
        return self
    end

    return field
end

function Fields.String(name) return CreateField(FieldTypes.STRING, name) end
function Fields.Integer(name) return CreateField(FieldTypes.INTEGER, name) end
function Fields.BigInt(name) return CreateField(FieldTypes.BIGINT, name) end
function Fields.Decimal(name) return CreateField(FieldTypes.DECIMAL, name) end
function Fields.Float(name) return CreateField(FieldTypes.FLOAT, name) end
function Fields.Text(name) return CreateField(FieldTypes.TEXT, name) end
function Fields.Boolean(name) return CreateField(FieldTypes.BOOLEAN, name) end
function Fields.Date(name) return CreateField(FieldTypes.DATE, name) end
function Fields.DateTime(name) return CreateField(FieldTypes.DATETIME, name) end
function Fields.Binary(name) return CreateField(FieldTypes.BINARY, name) end
function Fields.Json(name) return CreateField(FieldTypes.JSON, name) end
function Fields.Uuid(name) return CreateField(FieldTypes.UUID, name) end
