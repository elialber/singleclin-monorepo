# SingleClin Backend - Multi-stage Docker build

# Stage 1: Build environment
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app

# Copy csproj and restore dependencies (cached layer)
COPY *.csproj ./
RUN dotnet restore

# Copy source code
COPY . ./

# Build the application
RUN dotnet publish -c Release -o /app/publish \
    --no-restore \
    --self-contained false

# Stage 2: Runtime environment
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Create non-root user for security
RUN addgroup --system --gid 1001 singleclin && \
    adduser --system --uid 1001 --ingroup singleclin singleclin

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy published app from build stage
COPY --from=build /app/publish .

# Set ownership
RUN chown -R singleclin:singleclin /app

# Switch to non-root user
USER singleclin

# Environment variables
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_HTTP_PORTS=8080

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Entry point
ENTRYPOINT ["dotnet", "SingleClin.API.dll"]