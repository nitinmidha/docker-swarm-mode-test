(function(){var express = require('express');

var app = express();
var bodyParser = require('body-parser');

var port = process.env.PORT || 8000;

// Setup Middleware
app.use(bodyParser.urlencoded({extended:true}));
app.use(bodyParser.json());

app.use(function(req,res,next){
    console.info(req);
    next();
});

var os = require("os");
var hostname = os.hostname();


// Setup test routing
var router = express.Router();
router.get('/',function(req,res){
   res.json({message:'Success',
             container_id:hostname,
            host_req_hdr:req.headers["host"],
            x_nginx_container_id:req.headers["x-nginx-hostname"]
    });
});


router.get('/details',function(req,res){
   res.json({message:'Success',
             container_id:hostname,
            headers:req.headers
    });
});

router.get('/hostname',function(req,res){
   res.send(hostname)
});

app.use('/', router);

// Start listening
app.listen(port);

// Log that we are started ..
console.info('Server started on port '+ port);

})();
