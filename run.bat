docker run -it -p 9999:4000 ^
--name hexo ^
-v %cd%/_config.yml:/hexo/_config.yml ^
-v %cd%/source:/hexo/source ^
-v %cd%/themes/next/_config.yml:/hexo/themes/next/_config.yml ^
-v %cd%/themes/next/source/images/avatar.png:/hexo/themes/next/source/images/avatar.png ^
-v %cd%/themes/next/source/images/favicon.ico:/hexo/themes/next/source/images/favicon.ico ^
--env GIT_EMAIL="" ^
--env GIT_NAME="" ^
orenoid/hexo:latest