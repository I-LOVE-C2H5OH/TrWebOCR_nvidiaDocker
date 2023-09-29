nvidia docker image based on https://github.com/Desklop/docker_image_with_cuda10_cudnn7

TRWebOCR by https://github.com/alisen39/TrWebOCR

# Build: 
```
docker build -t trwebocrdocker .
```

# Run:
```
docker --gpus all --rm -p 8089:8089 -itd trwebocrdocker
```
