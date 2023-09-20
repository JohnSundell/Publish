#  How to use Videos


You can use videos on your pages. 
You need to do 2 things: 
- you define which video to include
- you define where to include the video on your page.

## which video to include

You need to include the video in your metadata:
```
---
title: Here the title of the item/page/section/index
...
video.tedTalk: celeste_headlee_10_ways_to_have_a_better_conversation
---

Now the content....

```

You can as well choose
- video.youtube
- video.vimeo
- video.url

## where to include the video

One way is to use this structure: 

```swift
    public struct VideoPlayerIfNeeded : Component{
        let video: Video?
        let height: String
        
        init(video: Video?, height: Int = 350) {
            self.video = video
            self.height = String(height)
        }
        
        var body: Component {
            video != nil ? VideoPlayer(video: video!,showControls: true).attribute(named:"height",value:self.height) : EmptyComponent() as Component
        }
    }
```

And then you can simply use it in your theme, e.g. 

```swift
    Article {
        H1(item.content.title)
        VideoPlayerIfNeeded(video: item.video)
        Div(item.content.body).class("content")
    }
```


## Alternatives
you can choose to use [this publish plugin](https://github.com/Vithanco/YoutubePublishPlugin).
