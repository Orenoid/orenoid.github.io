docker run -it -p 4000:4000 ^
--name hexo ^
-v %cd%/_config.yml:/hexo/_config.yml ^
-v %cd%/source:/hexo/source ^
-v %cd%/themes/next/_config.yml:/hexo/themes/next/_config.yml ^
-v %cd%/themes/next/source/images/avatar.png:/hexo/themes/next/source/images/avatar.png ^
-v %cd%/themes/next/source/images/favicon.ico:/hexo/themes/next/source/images/favicon.ico ^
-v /your/ssh/path:/tmp/.ssh ^
--env GIT_EMAIL="stefu1225@gmail.com" ^
--env GIT_NAME="Orenoid" ^
orenoid/hexo:latest
