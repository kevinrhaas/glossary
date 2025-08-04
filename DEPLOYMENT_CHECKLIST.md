# Quick Deployment Checklist

## ✅ Pre-Deployment Checklist

Your app is ready! Here's what you have:

- ✅ **Flask app** (`app.py`) - Ready with environment variable support
- ✅ **Docker container** (`Dockerfile`) - Multi-database support
- ✅ **Dependencies** (`requirements.txt`) - All database drivers included
- ✅ **Configuration** (`config.json`) - Default values set
- ✅ **Documentation** (`README.md`) - Complete API docs

## � Getting Your Image to Amazon ECR

### Option A: AWS CloudShell (Easiest - No Local Setup)
1. **Go to AWS Console** → Click CloudShell icon
2. **Upload your project files** (Dockerfile, app.py, requirements.txt, config.json)
3. **Run ECR commands** (see below)

### Option B: Temporary Credentials from Okta
1. **Get temp credentials**: https://hitachivantara.okta.com/home/amazon_aws/0oa155ztg8DWyKy732p7/272
2. **Export credentials** in your terminal
3. **Run ECR commands** (see below)

### Option C: GitHub Actions (Automated)
1. **Push to GitHub** (including .github/workflows/deploy-to-ecr.yml)
2. **Add AWS secrets** to GitHub repository settings
3. **Workflow runs automatically**

### ECR Commands (for CloudShell or Local Terminal):
```bash
# Create ECR repository
aws ecr create-repository --repository-name glossary-generator --region us-east-1

# Get account info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1

# Login to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and push
docker build -t glossary-generator .
docker tag glossary-generator:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/glossary-generator:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/glossary-generator:latest
```

## 🚀 Deploy with AWS App Runner

### 1. Your Image is Now in ECR!
Your Docker image should be at:
```
ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/glossary-generator:latest
```

### 2. Create App Runner Service
- Go to: https://console.aws.amazon.com/apprunner/
- Click "Create service"
- Source: Container registry → Amazon ECR
- **Browse and select your image**: `glossary-generator:latest`
- Service name: `glossary-generator-service`
- Port: `5000`

### 3. Set Environment Variables
Add these in the App Runner configuration:
```
DATABASE_URL = postgresql://neondb_owner:npg_2IVBxkpCLPj9@ep-rapid-poetry-a5zx9nzp-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require
API_BASE_URL = rg-llm-api-management.azure-api.net/openai-presales
API_KEY = 9a86acaf479142db935eb1691307d568
DATABASE_SCHEMA = fs_retbank_dimconsmktg
```

### 4. Deploy!
- Click "Create & deploy"
- Wait 5-10 minutes
- Test your service at the provided URL

## 🧪 Test Your Deployment

Once deployed, test these endpoints:
- `GET /health` - Service health check
- `GET /docs` - API documentation
- `POST /analyze` - Main analysis endpoint

## 📝 Environment Variables You'll Need

| Variable | Your Value | Example |
|----------|------------|---------|
| `DATABASE_URL` | _your database_ | `postgresql://user:pass@host:5432/db` |
| `API_BASE_URL` | _your API endpoint_ | `your-api-endpoint.com` |
| `API_KEY` | _your API key_ | `abc123...` |
| `DATABASE_SCHEMA` | _your schema_ | `public` |

## 💡 Tips

1. **Start with App Runner** - It's the easiest and handles scaling automatically
2. **Use environment variables** - Don't put credentials in code
3. **Test locally first** - Run `docker run -p 5000:5000 glossary-generator` to test
4. **Monitor logs** - CloudWatch logs will help debug issues

## 🆘 Need Help?

If you get stuck:
1. Check CloudWatch logs in the AWS console
2. Verify environment variables are set correctly
3. Test database connectivity from your local machine
4. Ensure your ECR image pushed successfully

Ready to deploy? Let me know which step you'd like help with!
