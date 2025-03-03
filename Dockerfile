FROM continuumio/miniconda3

# Set the working directory in the container to /app
WORKDIR /app

# Install the required packages
COPY environment.yaml /app
RUN apt update && apt install -y ffmpeg
RUN conda env create -f /app/environment.yaml

# Trigger WhisperX to download necessary models, so we can embed them in the image
COPY audio_nl.mp3 audio_en.mp3 /app
##RUN /bin/bash -c "source activate whisperx && cd /app; whisperx --hf_token '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' --model large-v2 --diarize --compute_type float32 --lang nl ./audio_nl.mp3"
ENV HF_TOKEN="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"

# Activate WhisperX and run model downloads
RUN /opt/conda/bin/conda run --no-capture-output -n whisperx \
    whisperx --hf_token $HF_TOKEN --model large-v2 --diarize --compute_type float32 --lang nl /app/audio_nl.mp3

RUN /opt/conda/bin/conda run --no-capture-output -n whisperx \
    whisperx --hf_token $HF_TOKEN --model large-v2 --diarize --compute_type float32 --lang en /app/audio_en.mp3

# Create uploads directory and set permissions
RUN mkdir -p /app/uploads && chmod 777 /app/uploads

# Copy the app itself
COPY app.py config.py /app/

# Make port 5000 available
EXPOSE 5000

# Define environment variable for Flask
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV FLASK_DEBUG=1

# Run the command to start your app
CMD ["/opt/conda/envs/whisperx/bin/gunicorn", "--bind", "0.0.0.0:5000", "--workers", "1", "--timeout", "300", "--log-level", "debug", "app:app"]
