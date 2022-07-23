import { AzureFunction, Context, HttpRequest } from "@azure/functions";
import * as crypto from "crypto";

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    context.log('HTTP trigger function processed a request.');
    context.log('JavaScript HTTP trigger function processed a request.');
    const secret = req.headers['x-logicapp-secret'];
    const hubsignature = req.headers['x-hub-signature'];
    const hmac = crypto.createHmac('sha256', secret);
    const buffer = JSON.stringify(req.body);
    hmac.update(buffer, 'utf8');
    const signature = `sha256=${hmac.digest('hex')}`;    
    const isValid = signature === hubsignature;
    
    context.res = {
        status: isValid ? 200 : 400,
        body: isValid
    };    
};

export default httpTrigger;