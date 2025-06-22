(
  docker run
    -p 8080:8080
    -e REWINGED_LISTEN='0.0.0.0:8080'
    -v $'(pwd)/manifests:/packages:ro'
    ghcr.io/jantari/rewinged:latest
)
