# Use official Python image
FROM python:3.10

# Set working directory inside the container
WORKDIR /app

# Copy project files
COPY . .

# Install dependencies
RUN pip install --upgrade pip
RUN pip install -r requirements.txt  
RUN pip install gunicorn  # Ensure Gunicorn is installed

# Expose port
EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "todoApp.wsgi:application"]
