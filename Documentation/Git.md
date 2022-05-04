# Git

## Work trouble

I got in trouble at work because I was using my work email address (angus.clinch@bailliegifford.com) to make commits on
my personal repository. While this is fine I was committing sensitive files that referenced secrets and the CSOC team
were getting alerts. This needs to be resolved.

## Fix it

Setting my username for this repository should override the global config and make it less error-prone than the
current system. The current system is that I need to select a checkbox everytime I make a commit and then write my
personal email (angus.clinch@gmail.com). I
followed [this guide](https://docs.github.com/en/get-started/getting-started-with-git/setting-your-username-in-git)
which recommends I use the following commands in the
directory of the repository.

    git config user.name clincha
    git config user.email angus.clinch@gmail.com

First I'll check what the current setting is:

    PS C:\Users\angus306\source\personal\clinch-home> git config user.email
    angus.clinch@bailliegifford.com
    PS C:\Users\angus306\source\personal\clinch-home> git config user.name 
    Angus Clinch

This is after I changed it:

    PS C:\Users\angus306\source\personal\clinch-home> git config user.email
    angus.clinch@gmail.com
    PS C:\Users\angus306\source\personal\clinch-home> git config user.name
    clincha

I was also expecting to see a .git directory added to the repository, but I can't see that anywhere. Not sure where the
Git user and email information
is stored for repository based systems.

## Result

Yay! It worked

![it worked.png](Images/Git/it-worked.png)
