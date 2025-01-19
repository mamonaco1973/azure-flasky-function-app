variable "authorization_level" {
  description = "What type of authorization to require on the function"
  type        =  string
  default     = "ANONYMOUS" 
#  default     = "FUNCTION"
}
