# 1. Tabela DynamoDB para Telemetria
resource "aws_dynamodb_table" "telemetria" {
  name           = "${var.project_name}-dados"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "device_id"
  range_key      = "timestamp"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  tags = {
    Project = var.project_name
  }
}

# 2. Bucket S3 para Firmware (OTA)
resource "aws_s3_bucket" "firmware" {
  bucket = "${var.project_name}-firmware-repo"
}

# 3. AWS IoT Thing (O Objeto no IoT Core)
resource "aws_iot_thing" "esp32c6_medidor" {
  name = var.device_id
}

# 4. Role para a IoT Rule (Permitir que a regra escreva no DynamoDB)
resource "aws_iam_role" "iot_to_dynamodb_role" {
  name = "${var.project_name}-iot-to-db-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "iot.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "iot_dynamodb_policy" {
  name = "${var.project_name}-iot-db-policy"
  role = aws_iam_role.iot_to_dynamodb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem"
      ]
      Resource = [aws_dynamodb_table.telemetria.arn]
    }]
  })
}

# 5. IoT Topic Rule (A "Ponte" entre MQTT e DynamoDB)
resource "aws_iot_topic_rule" "energia_rule" {
  name        = "EnergiaToDynamoDB"
  description = "Envia dados de telemetria do ESP32 para o DynamoDB"
  enabled     = true
  sql         = "SELECT * FROM 'energia/${var.device_id}/dados'"
  sql_version = "2016-03-23"

  dynamodbv2 {
    put_item {
      table_name = aws_dynamodb_table.telemetria.name
    }
    role_arn = aws_iam_role.iot_to_dynamodb_role.arn
  }
}

# 6. IoT Policy (Princípio do Privilégio Mínimo)
resource "aws_iot_policy" "esp32_policy" {
  name = "${var.project_name}-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["iot:Connect"]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        Action   = ["iot:Publish"]
        Effect   = "Allow"
        Resource = ["arn:aws:iot:${var.aws_region}:*:topic/energia/${var.device_id}/dados"]
      }
    ]
  })
}