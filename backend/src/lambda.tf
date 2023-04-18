provider "aws" {
  region = "ap-south-1"
  access_key = "TOP_SECRET"
  secret_key = "TOP_SECRET"
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role" "lambda_role" {
  name = "obituary-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "obituary-policy" {
  name = "obituary-policy"
  role = aws_iam_role.lambda_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ssm:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "states:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "polly:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Get Obituaries

resource "aws_lambda_function" "get-obituary-lambda" {
  filename         = "obituaries_retriever_handler.zip"
  function_name    = "get-obituaries-lambda-3016768"
  role             = aws_iam_role.lambda_role.arn
  handler          = "obituaries_retriever_handler.lambda_handler"
  runtime          = "python3.9"
  timeout          = 20
  memory_size      = 128
  environment {
    variables = {
      TABLE_NAME = "prod-obituary-data-3043657"
    }
  }
}

data "archive_file" "obituaries_retriever_handler" {
  type        = "zip"
  source_file  = "${path.module}/handlers/obituaries_retriever_handler.py"
  output_path = "obituaries_retriever_handler.zip"
}

resource "aws_lambda_function_url" "get_obituaries_url" {
  function_name      = aws_lambda_function.get-obituary-lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive", "access-control-allow-origin", "access-control-request-methods", "access-control-allow-headers"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 0
  }
}


# STEP 1

resource "aws_lambda_function" "step-1-generate-obituary-lambda" {
  filename         = "generate_obituary_handler.zip"
  function_name    = "step-1-generate-obituary-3016768"
  role             = aws_iam_role.lambda_role.arn
  handler          = "generate_obituary_handler.lambda_handler"
  runtime          = "python3.9"
  timeout          = 20
  memory_size      = 128
  layers           = ["arn:aws:lambda:ap-south-1:589769605795:layer:requests-layer:1"]
  environment {
    variables = {
      TABLE_NAME = "prod-obituary-data-3043657"
    }
  }
}

data "archive_file" "generate_obituary_handler" {
  type        = "zip"
  source_file  = "${path.module}/handlers/generate_obituary_handler.py"
  output_path = "generate_obituary_handler.zip"
}

# STEP 2 read_obituary_mp3_handler

resource "aws_lambda_function" "step-2-read-obituary-mp3-handler" {
  filename         = "read_obituary_mp3_handler.zip"
  function_name    = "step-2-read-obituary-mp3-3016768"
  role             = aws_iam_role.lambda_role.arn
  handler          = "read_obituary_mp3_handler.lambda_handler"
  runtime          = "python3.9"
  timeout          = 10
  memory_size      = 128
  layers           = ["arn:aws:lambda:ap-south-1:589769605795:layer:requests-layer:1"]
  environment {
    variables = {
      TABLE_NAME = "prod-obituary-data-3043657"
    }
  }
}

data "archive_file" "read_obituary_mp3_handler" {
  type        = "zip"
  source_file  = "${path.module}/handlers/read_obituary_mp3_handler.py"
  output_path = "read_obituary_mp3_handler.zip"
}

# STEP 3 validate_files_handler

resource "aws_lambda_function" "step-3-validate-files-handler" {
  filename         = "validate_files_handler.zip"
  function_name    = "step-3-validate-files-3016768"
  role             = aws_iam_role.lambda_role.arn
  handler          = "validate_files_handler.lambda_handler"
  runtime          = "python3.9"
  timeout          = 5
  memory_size      = 128
  layers           = ["arn:aws:lambda:ap-south-1:589769605795:layer:requests-layer:1"]
  environment {
    variables = {
      TABLE_NAME = "prod-obituary-data-3043657"
    }
  }
}

data "archive_file" "validate_files_handler" {
  type        = "zip"
  source_file  = "${path.module}/handlers/validate_files_handler.py"
  output_path = "validate_files_handler.zip"
}

# STEP 4 save_obituary_handler

resource "aws_lambda_function" "step-4-save-obituary-handler" {
  filename         = "save_obituary_handler.zip"
  function_name    = "step-4-save-obituary-3016768"
  role             = aws_iam_role.lambda_role.arn
  handler          = "save_obituary_handler.lambda_handler"
  runtime          = "python3.9"
  timeout          = 6
  memory_size      = 128
  layers           = ["arn:aws:lambda:ap-south-1:589769605795:layer:requests-layer:1"]
  environment {
    variables = {
      TABLE_NAME = "prod-obituary-data-3043657"
    }
  }
}

data "archive_file" "save_obituary_handler" {
  type        = "zip"
  source_file  = "${path.module}/handlers/save_obituary_handler.py"
  output_path = "save_obituary_handler.zip"
}


# STEP FUNCTION 
resource "aws_iam_role_policy" "lambda-invoke-policy" {
  name = "lambda-invoke-policy"
  role = aws_iam_role.step_function_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "step_function_role" {
  name = "step-function-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "step_function_policy_attachment" {
  # arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
  role       = aws_iam_role.step_function_role.name
}


resource "aws_sfn_state_machine" "obituary_state_machine" {
  name     = "obituary-creation-step-fn"
  role_arn = aws_iam_role.step_function_role.arn
  definition = <<DEFINITION
{
  "Comment": "A description of my state machine",
  "StartAt": "generate-obituary",
  "States": {
    "generate-obituary": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${aws_lambda_function.step-1-generate-obituary-lambda.arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "read-obituary",
      "InputPath": "$",
      "ResultPath": "$"
    },
    "read-obituary": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${aws_lambda_function.step-2-read-obituary-mp3-handler.arn}",
        "Payload.$": "$"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "validate-stored-file",
      "InputPath": "$",
      "ResultPath": "$"
    },
    "validate-stored-file": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${aws_lambda_function.step-3-validate-files-handler.arn}",
        "Payload.$": "$"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "save-item",
      "InputPath": "$",
      "ResultPath": "$"
    },
    "save-item": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${aws_lambda_function.step-4-save-obituary-handler.arn}",
        "Payload.$": "$"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "End": true,
      "InputPath": "$",
      "ResultPath": "$"
    }
  }
}
DEFINITION
}

# STEP 0 initiate_steps_handler

resource "aws_lambda_function" "step-0-initiate-steps-handler" {
  filename         = "initiate_steps_handler.zip"
  function_name    = "step-0-initiate-steps-3016768"
  role             = aws_iam_role.lambda_role.arn
  handler          = "initiate_steps_handler.lambda_handler"
  runtime          = "python3.9"
  timeout          = 40
  memory_size      = 128
  layers           = ["arn:aws:lambda:ap-south-1:589769605795:layer:requests-layer:1"]
  environment {
    variables = {
      TABLE_NAME = "prod-obituary-data-3043657"
      STEP_FN_ARN = aws_sfn_state_machine.obituary_state_machine.arn
    }
  }
}

data "archive_file" "initiate_steps_handler" {
  type        = "zip"
  source_file  = "${path.module}/handlers/initiate_steps_handler.py"
  output_path = "initiate_steps_handler.zip"
}

resource "aws_lambda_function_url" "invoker_url" {
  function_name      = aws_lambda_function.step-0-initiate-steps-handler.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive", "access-control-allow-origin", "access-control-request-methods", "access-control-allow-headers"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 0
  }
}
