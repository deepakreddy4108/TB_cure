from flask import Flask, request, jsonify
import numpy as np
import tensorflow as tf
from PIL import Image
from tensorflow.keras.losses import MeanSquaredError

# Initialize the Flask app
app = Flask(__name__)

# Suppress oneDNN warnings
import os
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

# Load the .h5 regression model without compilation
model = tf.keras.models.load_model('module_regression_model.h5', compile=False)

# Compile the model explicitly with the required optimizer and loss function
model.compile(optimizer='adam', loss=MeanSquaredError())

# Define a function to preprocess and reshape the image
def preprocess_image(image, target_size):
    # Resize image to match the model's expected input size (e.g., 128x128)
    image = image.resize(target_size)  # Resize the image
    image = np.array(image).astype('float32') / 255.0  # Normalize to [0, 1]

    # Check the number of channels
    if image.ndim == 2:  # If the image is grayscale (2D)
        image = np.expand_dims(image, axis=-1)  # Add channel dimension (make it 1 channel)

    image = np.expand_dims(image, axis=0)  # Add batch dimension
    return image


# Define the prediction function
def predict_image(image_file):
    try:
        # Load and preprocess the image directly from the file
        img = Image.open(image_file).convert('L')  # Convert to grayscale (L mode is for grayscale)
        processed_img = preprocess_image(img, (128, 128))  # Reshape to 128x128 for grayscale image

        # Run the prediction using the .h5 model
        prediction = model.predict(processed_img)

        # Get the regression value (output of the model)
        regression_value = prediction[0][0]  # Extracting the regression value from ndarray

        # If the regression value is greater than 2, classify as "Thick", otherwise "Thin"
        predicted_class = 'Thick' if regression_value > 2 else 'Thin'

        # Return both classification and regression value
        return predicted_class, float(regression_value)  # Convert regression_value to float
    except Exception as e:
        print(f"Error during prediction: {e}")
        return "Error during prediction", None


# API route for image prediction
@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({"error": "No image file provided"}), 400

    # Get the image from the request
    image_file = request.files['image']

    # Run the prediction directly from the image file
    predicted_class, regression_value = predict_image(image_file)

    # If an error occurred during prediction, return it
    if predicted_class == "Error during prediction":
        return jsonify({"error": "Error during prediction"}), 500

    # Return the prediction result with both classification and regression value
    return jsonify({
        "prediction": predicted_class,  # Class (Thick/Thin)
        "regression_value": regression_value  # The regression value
    })


if __name__ == '__main__':
    # Run the Flask app
    app.run(debug=True)
