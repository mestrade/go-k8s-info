FROM scratch
EXPOSE 8080
ENTRYPOINT ["/go-k8s-info"]
COPY ./bin/ /