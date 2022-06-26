# Git

## Work trouble

I got in trouble at work because I was using my work email address (angus.clinch@bailliegifford.com) to make commits on
my personal repository. While this is fine normally, I was committing files that referenced my GitHub secrets
and the CSOC team were getting alerts. This needs to be resolved so that I don't waste peoples time when I'm using my
work laptop to commit personal work. The current system is that I need to select a checkbox every time I make a commit
and then write my personal email (angus.clinch@gmail.com) in a box.

![old-system.png](Images/Git/old-system.png)

## Fix it

Setting my username in the git configuration for this repository should override the global configuration on my work device. I
followed [this guide](https://docs.github.com/en/get-started/getting-started-with-git/setting-your-username-in-git)
which recommends I use the following commands in the directory of the repository.

    git config user.name clincha
    git config user.email angus.clinch@gmail.com

First I'll check what the current setting is:

    PS C:\Users\angus306\source\personal\clinch-home> git config user.email
    angus.clinch@bailliegifford.com
    PS C:\Users\angus306\source\personal\clinch-home> git config user.name 
    Angus Clinch

Then I'll change it (using the above commands) and inspect the result again:

    PS C:\Users\angus306\source\personal\clinch-home> git config user.email
    angus.clinch@gmail.com
    PS C:\Users\angus306\source\personal\clinch-home> git config user.name
    clincha

Looks like it's worked locally. I was expecting to see a .git directory added to the repository, but I can't see that
anywhere. Not sure where the Git user and email information is stored for repository based configuration.

## Result

Yay! It worked

![it worked.png](Images/Git/it-worked.png)
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTY3MDMwNjI2NF19
-->