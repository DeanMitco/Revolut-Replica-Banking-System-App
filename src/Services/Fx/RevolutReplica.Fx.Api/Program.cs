var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();

var app = builder.Build();

// Liveness only; database and broker readiness are added with their integrations.
app.MapHealthChecks("/health/public");

app.Run();
