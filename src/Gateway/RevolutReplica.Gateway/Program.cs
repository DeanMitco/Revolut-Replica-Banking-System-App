var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();

var app = builder.Build();

// Step 1 checks the host only. Proxy routes and JWT validation arrive in Step 2.
app.MapHealthChecks("/health/public");

app.Run();
