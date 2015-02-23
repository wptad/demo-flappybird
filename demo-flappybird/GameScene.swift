//
//  GameScene.swift
//  demo-flappybird
//
//  Created by Tad Wang on 2/23/15.
//  Copyright (c) 2015 retrylab. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    var bird = SKSpriteNode();
    var skyColor = SKColor();
    var verticalPipeGap = 150.0;
    var pipeTextureUp = SKTexture();
    var pipeTextureDown = SKTexture();
    var movePipesAndRemove = SKAction();
    
    override func didMoveToView(view: SKView) {
        // 设置物理世界属性
        self.physicsWorld.gravity = CGVectorMake( 0.0, -5.0 )//设置重力值
        
        // 设置背景颜色
        skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
        
        // 构建地面
        var groundTexture = SKTexture(imageNamed: "land")//调用地面纹理素材图片
        //纹理过滤模式
        groundTexture.filteringMode = SKTextureFilteringMode.Nearest
        //移动地面材质Sprite
        var moveGroundSprite = SKAction.moveByX(-groundTexture.size().width * 2.0, y: 0, duration: NSTimeInterval(0.02 * groundTexture.size().width * 2.0))
        //移动后在屏幕界面中重置地面Sprite
        var resetGroundSprite = SKAction.moveByX(groundTexture.size().width * 2.0, y: 0, duration: 0.0)
        var moveGroundSpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))
        
        for var i:CGFloat = 0; i < 2.0 + self.frame.size.width / ( groundTexture.size().width * 2.0 ); ++i {
            var sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2.0)
            sprite.runAction(moveGroundSpritesForever)
            self.addChild(sprite)
        }
        
        //天际线
        var skyTexture = SKTexture(imageNamed: "sky")//调用指定的天空素材图片
        //天空纹理
        skyTexture.filteringMode = SKTextureFilteringMode.Nearest
        //移动天空材质Sprite
        var moveSkySprite = SKAction.moveByX(-skyTexture.size().width * 2.0, y: 0, duration: NSTimeInterval(0.1 * skyTexture.size().width * 2.0))
        //移动后在屏幕界面中重置天空Sprite
        var resetSkySprite = SKAction.moveByX(skyTexture.size().width * 2.0, y: 0, duration: 0.0)
        var moveSkySpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveSkySprite,resetSkySprite]))
        
        for var i:CGFloat = 0; i < 2.0 + self.frame.size.width / ( skyTexture.size().width * 2.0 ); ++i {
            var sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(2.0)
            sprite.zPosition = -20;
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2.0 + groundTexture.size().height * 2.0)
            sprite.runAction(moveSkySpritesForever)
            self.addChild(sprite)
        }
        
        // 构建上方和下放阻挡小鸟飞行的管道的纹理
        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = SKTextureFilteringMode.Nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = SKTextureFilteringMode.Nearest
        
        // 实现移动阻挡管道效果
        var distanceToMove = CGFloat(self.frame.size.width + 2.0 * pipeTextureUp.size().width);
        var movePipes = SKAction.moveByX(-distanceToMove, y:0.0, duration:NSTimeInterval(0.01 * distanceToMove));
        var removePipes = SKAction.removeFromParent();
        movePipesAndRemove = SKAction.sequence([movePipes, removePipes]);
        
        // 启动另外一个进程并通过管道与其进行通信
        var spawn = SKAction.runBlock({() in self.spawnPipes()})
        var delay = SKAction.waitForDuration(NSTimeInterval(2.0))
        var spawnThenDelay = SKAction.sequence([spawn, delay])
        var spawnThenDelayForever = SKAction.repeatActionForever(spawnThenDelay)
        self.runAction(spawnThenDelayForever)
        
        // 设置我的小鸟
        var birdTexture1 = SKTexture(imageNamed: "bird-01")//第一种鸟的素材图像
        birdTexture1.filteringMode = SKTextureFilteringMode.Nearest
        var birdTexture2 = SKTexture(imageNamed: "bird-02")//第二种鸟的素材图像
        birdTexture2.filteringMode = SKTextureFilteringMode.Nearest
        
        //第一种鸟通过动画来衔接第二种鸟样式，这样可以达到震动翅膀飞翔的效果
        var anim = SKAction.animateWithTextures([birdTexture1, birdTexture2], timePerFrame: 0.2)
        var flap = SKAction.repeatActionForever(anim)
        
        bird = SKSpriteNode(texture: birdTexture1)
        bird.setScale(2.0)
        bird.position = CGPoint(x: self.frame.size.width * 0.35, y:self.frame.size.height * 0.6)
        bird.runAction(flap)
        
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0);
        
        bird.physicsBody!.dynamic = true
        bird.physicsBody!.allowsRotation = false
        
        self.addChild(bird)
        
        //创建地面
        var ground = SKNode()
        ground.position = CGPointMake(0, groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, groundTexture.size().height * 2.0))
        ground.physicsBody!.dynamic = false
        self.addChild(ground)
    }
    
    //实现新管道，移动位置，构建小鸟上、下、前进飞翔的物理世界
    func spawnPipes() {
        var pipePair = SKNode()
        pipePair.position = CGPointMake( self.frame.size.width + pipeTextureUp.size().width * 2, 0 );
        pipePair.zPosition = -10;
        
        var height = UInt32( self.frame.size.height / 4 )
        var y = arc4random() % height + height;
        
        var pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(2.0)
        pipeDown.position = CGPointMake(0.0, CGFloat(y) + pipeDown.size.height + CGFloat(verticalPipeGap))
        
        
        pipeDown.physicsBody = SKPhysicsBody(rectangleOfSize: pipeDown.size)
        pipeDown.physicsBody!.dynamic = false
        pipePair.addChild(pipeDown)
        
        var pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(2.0)
        pipeUp.position = CGPointMake(0.0, CGFloat(y))
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOfSize: pipeUp.size)
        pipeUp.physicsBody!.dynamic = false
        pipePair.addChild(pipeUp)
        
        pipePair.runAction(movePipesAndRemove);
        self.addChild(pipePair)
    }
    
    //触摸屏幕后开始游戏
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            
            bird.physicsBody!.velocity = CGVectorMake(0, 0)
            bird.physicsBody!.applyImpulse(CGVectorMake(0, 30))
            
        }
    }
    
    //设置上下移动的最大界限和最小界限
    func clamp(min: CGFloat, max: CGFloat, value: CGFloat) -> CGFloat {
        if( value > max ) {
            return max;
        } else if( value < min ) {
            return min;
        } else {
            return value;
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        bird.zRotation = self.clamp( -1, max: 0.5, value: bird.physicsBody!.velocity.dy * ( bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001 ) );
    }
}
