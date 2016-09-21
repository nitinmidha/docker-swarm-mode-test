FROM nginx:1.11.3
RUN rm /etc/nginx/conf.d/default.conf
RUN mkdir /etc/nginx/logs
COPY nginx.template.conf /etc/nginx/
CMD ["/bin/bash","-c","cat /etc/nginx/nginx.template.conf > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"]
