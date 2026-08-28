output "bucket_name" {
  description = "Bucket donde se guardan los tipos de cambio"
  value       = aws_s3_bucket.rates.id
}

output "lambda_function_name" {
  description = "Nombre de la función Lambda"
  value       = aws_lambda_function.rates.function_name
}

output "schedule_name" {
  description = "Nombre de la programación diaria"
  value       = aws_scheduler_schedule.daily.name
}