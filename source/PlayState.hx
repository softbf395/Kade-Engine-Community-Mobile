package;

import Song.StyleData;
import Song.Style;
import lime.utils.Assets as LimeAssets;
import flixel.group.FlxSpriteGroup;
import shader.Shaders;
import shader.RuntimeShader;
import flixel.addons.display.FlxRuntimeShader;
import flixel.util.FlxSpriteUtil;
import openfl.utils.Assets as OpenFlAssets;
#if FEATURE_LUAMODCHART
import LuaClass;
#end
import openfl.filters.BitmapFilter;
import lime.media.openal.AL;
import Song.Event;
import openfl.media.Sound;
#if FEATURE_STEPMANIA
import smTools.SMFile;
#end
#if FEATURE_FILESYSTEM
import sys.io.File;
import Sys;
import sys.FileSystem;
#end
import openfl.events.Event;
import openfl.ui.Keyboard;
import openfl.events.KeyboardEvent;
import flixel.input.keyboard.FlxKey;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import flixel.graphics.FlxGraphic;
import lime.app.Application;
import openfl.Lib;
import Section.SwagSection;
import Song.SongData;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import openfl.filters.ShaderFilter;
#if FEATURE_DISCORD
import Discord;
#end
#if FEATURE_HSCRIPT
import script.Script;
import script.ScriptGroup;
import script.ScriptUtil;
#end
// Orginization Imports
import debug.StageDebugState;
import debug.ChartingState;
#if VIDEOS
import hxvlc.flixel.FlxVideo as VideoHandler;
import hxvlc.flixel.FlxVideoSprite as VideoSprite;
import hxvlc.util.Handle;
#end
import stages.Stage;
import stages.TankmenBG;
import Ratings.RatingWindow;
import MusicBeatState.subStates;

using StringTools;

class PlayState extends MusicBeatState
{
	// PlayState But Static.
	public static var instance:PlayState = null;

	// SONG MULTIPLIER STUFF
	public var speedChanged:Bool = false;
	public var previousRate:Float = songMultiplier;

	public static var songMultiplier:Float = 1.0;

	// Scroll Speed changes multiplier
	public var scrollSpeed(default, set):Float = 1.0;
	public var scrollMult:Float = 1.0;
	public var scrollTween:FlxTween;

	// Fake crochet for Sustain Notes
	public var fakeCrochet:Float = 0;
	public var fakeNoteStepCrochet:Float;

	// I shit my pants
	// Song Data. Very Useful Uses Like SONG.songId Or Some Shit.
	public static var SONG:SongData;

	// Style Data. Like Pixel Or Default Or Something. Controls The UI Basically.
	public static var STYLE:StyleData;

	// Better To Use SONG.songId But Works Too Ig.
	private var curSong:String = "";

	// Story Shit, Not That Useful Aside From isStoryMode and storyDifficulty.
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var weekSong:Int = 0;
	public static var weekScore:Int = 0;
	public static var campaignScore:Int = 0;

	// Amount Of Ratings
	public static var shits:Int = 0;
	public static var bads:Int = 0;
	public static var goods:Int = 0;
	public static var sicks:Int = 0;
	public static var marvs:Int = 0;

	// Stores HUD Elements in a Group
	public var uiGroup:FlxSpriteGroup;

	// The Number Your Combo Is.
	private var combo:Int = 0;

	// Highest Your Combo Has Been.
	public static var highestCombo:Int = 0;

	// Misses, Campaign Ratings Used For The Score Screen.
	public static var misses:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var campaignMarvs:Int = 0;
	public static var campaignSicks:Int = 0;
	public static var campaignGoods:Int = 0;
	public static var campaignBads:Int = 0;
	public static var campaignShits:Int = 0;
	public static var campaignAccuracy:Float = 0.00;

	// Accuracy. totalNotesHit Used For Accuracy.
	public var accuracy:Float = 0.00;

	private var accuracyDefault:Float = 0.00;

	private var totalNotesHitDefault:Float = 0;
	private var totalNotesHit:Float = 0;

	private var totalPlayed:Int = 0;

	// The Actual MS Timing.
	public var msTiming:Float;

	// Current Score
	public var songScore:Int = 0;

	// Idk.
	var songScoreDef:Int = 0;
	// Text For Accuracy, Score, Misses, Etc.
	var scoreTxt:FlxText;
	// How Many Marvs, Sicks, Etc.
	var judgementCounter:FlxText;

	// Tween And Timer Manager. Don't Mess With These.
	public static var tweenManager:FlxTweenManager;
	public static var timerManager:FlxTimerManager;

	#if FEATURE_HSCRIPT
	// Hscript Group (All Of The Loaded Scripts)
	public var scripts:ScriptGroup;
	#end

	// HScript And Lua Stuff. If There's A File, It'll Be True.
	public var executeModchart = false;
	public var executeHScript = false;
	public var runHscript = false;

	// Character Animation Related
	var currentFrames:Int = 0;
	var idleToBeat:Bool = true; // change if bf and dad would idle to the beat of the song
	var idleBeat:Int = 2; // how frequently bf and dad would play their idle animation(1 - every beat, 2 - every 2 beats and so on)
	var forcedToIdle:Bool = false; // change if bf and dad are forced to idle to every (idleBeat) beats of the song
	var allowedToHeadbang:Bool = true; // Will decide if gf is allowed to headbang depending on the song
	var allowedToCheer:Bool = false; // Will decide if gf is allowed to cheer depending on the song

	// Note Animation Suffixes.
	private var dataSuffix:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	private var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];

	// Tracks The Last Score (I Don't Know What It Does.)
	public static var lastScore:Array<FlxSprite> = [];

	// BotPlay text
	public var addedBotplay:Bool = false;

	public var botPlayState:FlxText;

	// All The Notes
	public var notes:FlxTypedGroup<Note>;
	// Non Visible Notes.
	public var unspawnNotes:Array<Note> = [];

	// MS Timing For Notes?
	var notesHitArray:Array<Float> = [];

	// Array that should make some notes easier to hit
	public static var lowPriorityNotes:Array<String> = CoolUtil.noteShitArray;

	// Noteskin And Notesplash Related Stuff.
	public static var noteskinSprite:String;
	public static var cpuNoteskinSprite:String;
	public static var notesplashSprite:String;
	public static var noteskinPixelSprite:FlxGraphic;
	public static var noteskinPixelSpriteEnds:FlxGraphic;

	// If The Arrows Are Generated / Shown.
	public var arrowsGenerated:Bool = false;

	// New Input / Ghost Tapping. Idk It's Pretty Outdated.
	public static var theFunne:Bool = true;

	// Replay Stuff
	public static var inResults:Bool = false;

	// If Is In PlayState.
	public static var inDaPlay:Bool = false;

	// If You Can Skip To Where Notes Start In A Song (Freeplay Only.)
	var needSkip:Bool = false;
	var skipActive:Bool = false;
	var skipText:Alphabet;
	var skipTo:Float;

	// If You Did Skip Ahead.
	var usedTimeTravel:Bool = false;

	public var storyDifficultyText:String = "";

	#if FEATURE_DISCORD
	// Discord RPC variables
	var iconRPC:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	// Voices And Instrumental Sounds. Best Not To Mess With These Too Much.
	public static var vocals:FlxSound;
	public static var vocalsPlayer:FlxSound;
	public static var vocalsEnemy:FlxSound;
	public static var inst:FlxSound;

	// Stepmania Variables.
	public static var isSM:Bool = false;
	public static var pathToSm:String;
	#if FEATURE_STEPMANIA
	public static var sm:SMFile;
	#end

	// Notesplashes
	private var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	// Camera Zoom Related. zoomMultiplier Multiplies The Camera Zoom Amount (Every 4 Steps)
	public var zoomForTweens:Float = 0;
	public var zoomForHUDTweens:Float = 1;
	public var zoomMultiplier:Float = 1;

	// Characters, Very Useful.
	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	// I'll come back to this later but basically is unused for now.
	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	public var boyfriendGroup:FlxTypedGroup<Character>;
	public var dadGroup:FlxTypedGroup<Character>;
	public var gfGroup:FlxTypedGroup<Character>;

	// The Stage.
	public var Stage:Stage = null;

	// Not Important. Ignore This.
	public var strumLine:FlxSprite;

	// What The Camera Focus' On.
	private var camFollow:FlxObject;

	// The Actual Camera Position.
	var camPos:FlxPoint;

	// I Have No Idea.
	private static var prevCamFollow:FlxObject;

	// Strumline (Static Notes)
	public static var strumLineNotes:FlxTypedGroup<StaticArrow> = null;
	public static var playerStrums:FlxTypedGroup<StaticArrow> = null;
	public static var cpuStrums:FlxTypedGroup<StaticArrow> = null;

	public var arrowLanes:FlxTypedGroup<FlxSprite> = null;

	// When The Camera Zooms On Beat
	private var camZooming:Bool = false;

	// No Idea.
	private var gfSpeed:Int = 1;

	// Health Stuff. Important. shownHealth Is Just Health But Allows Lerping (Smooth Healthbar. Don't Touch shownHealth.)
	public var health:Float = 1;
	public var shownHealth:Float = 1;

	// Icons For The Healthbar. Ignore The AnimArrays. It's Used For Animated Icons.
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	var icon1AnimArray:Array<Bool> = [false, false];
	var icon2AnimArray:Array<Bool> = [false, false];
	var animName:String = 'Idle'; // Animated Icon Stuff.

	// Healthbar Related Stuff. Making Custom Ones Just Means Loading The Image Later In The Code 9/10 Times.
	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;
	var barImage:FlxGraphic; // The Actual Image Itself.

	// Song Position Bar. Self Explainitory.
	private var songPositionBar:Float = 0;

	public static var songPosBar:FlxBar;
	public static var songPosBG:FlxSprite;

	// Song Position Song Name.
	var songName:FlxText;

	// Self Explainitory.
	var songLength:Float = 0;

	// If The Song Has Been Generated.
	private var generatedMusic:Bool = false;
	// If The Song Has Started Playing.
	private var startingSong:Bool = false;

	// All The Cameras Used Ingame.
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var camStrums:FlxCamera;
	public var overlayCam:FlxCamera;

	// The Shaders (I Have No Idea What They Do That Much.)
	public var camHUDShaders:Array<ShaderEffect> = [];
	public var camGameShaders:Array<ShaderEffect> = [];
	public var shaderUpdates:Array<Float->Void> = [];
	public var camStrumsShaders:Array<ShaderEffect> = [];
	public var overlayShaders:Array<ShaderEffect> = [];

	// Can The Player Die. Only Used When Switching States Or Something.
	public var cannotDie = false;

	// I don't know.
	public static var offsetTesting:Bool = false;

	// Dialogue For Week 6 And Whatnot.
	public var dialogue:Array<String> = [];

	// I'm Not Sure Why This Exists.
	var wiggleShit:WiggleEffect = new WiggleEffect();

	// Kinda The Same Thing.
	var inCutscene:Bool = false;

	public var inCinematic:Bool = false;

	// From What I Can Tell, It's Just Used For StageDebugState.
	public static var stageTesting:Bool = false;

	// Will fire once to prevent debug spam messages and broken animations
	private var triggeredAlready:Bool = false;

	// Per song additive offset
	public static var songOffset:Float = 0;

	// Self Explainitory.
	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	// Self Explainitory.
	public static var startTime = 0.0;

	#if VIDEOS
	// Week 7 Cutscenes. You Can Use It Your Own Way Too.
	public var cutscene:VideoHandler;
	#end

	// """Cheat Detection"""
	public static var usedBot:Bool = false;
	public static var wentToChartEditor:Bool = false;

	public var initStoryLength:Int = 0;

	var tweenBoolshit = true;

	// Default Note X Positions (Non Middlescroll). Used For Modcharts If You Want.
	var notePositions:Array<Float> = [92, 204, 316, 428, 732, 844, 956, 1068];

	// Adding Objects Using Lua
	public function addObject(object:FlxBasic)
	{
		add(object);
	}

	// Removing Objects Using Lua
	public function removeObject(object:FlxBasic)
	{
		remove(object);
	}

	override public function create()
	{
		var stamp:Float = haxe.Timer.stamp();
		if (curSong != SONG.songId)
		{
			curSong = SONG.songId;
			Paths.clearStoredMemory();
		}

		// Initialize The Scripts.
		#if FEATURE_HSCRIPT
		scripts = new ScriptGroup();
		scripts.onAddScript.push(onAddScript);
		#end

		FlxG.mouse.visible = false;
		instance = this;

		// Setup The Tween / Timer Manager.
		tweenManager = new FlxTweenManager();
		timerManager = new FlxTimerManager();

		// Load User's Keybinds.
		PlayerSettings.player1.controls.loadKeyBinds();

		// Change The Application Title To The Engine Version, Song Name, And Difficulty.
		Application.current.window.title = '${MainMenuState.kecVer}: ${SONG.songName} - [${CoolUtil.difficultyArray[storyDifficulty]}]';

		STYLE = Style.loadJSONFile(SONG.style.toLowerCase());

		if (STYLE == null)
		{
			STYLE = Style.loadJSONFile('default');
			Debug.logTrace("No Style Found. Loading Default.");
		}
		STYLE.style = SONG.style;

		// grab variables here too or else its gonna break stuff later on
		GameplayCustomizeState.freeplayBf = SONG.player1;
		GameplayCustomizeState.freeplayDad = SONG.player2;
		GameplayCustomizeState.freeplayGf = SONG.gfVersion;
		GameplayCustomizeState.freeplayNoteStyle = SONG.style.toLowerCase();
		GameplayCustomizeState.freeplayStage = SONG.stage;
		GameplayCustomizeState.freeplaySong = SONG.songId;
		GameplayCustomizeState.freeplayWeek = storyWeek;

		previousRate = songMultiplier - 0.05;

		if (previousRate < 1.00)
			previousRate = 1;

		// Stop Freeplay / Story Menu Music.
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		inDaPlay = true;

		// Set Rating Amounts To 0.
		marvs = 0;
		sicks = 0;
		bads = 0;
		shits = 0;
		goods = 0;
		misses = 0;

		highestCombo = 0;
		inResults = false;

		// Initialize PlayStateChangeables Options For Later.
		PlayStateChangeables.useDownscroll = FlxG.save.data.downscroll;
		PlayStateChangeables.middleScroll = FlxG.save.data.middleScroll;
		PlayStateChangeables.safeFrames = FlxG.save.data.frames;
		if (FlxG.save.data.scrollSpeed == 1)
			scrollSpeed = SONG.speed;
		else
			scrollSpeed = FlxG.save.data.scrollSpeed;
		PlayStateChangeables.zoom = FlxG.save.data.zoom;
		PlayStateChangeables.botPlay = FlxG.save.data.botplay;

		if (!isStoryMode)
		{
			PlayStateChangeables.modchart = FlxG.save.data.modcharts;
			PlayStateChangeables.opponentMode = FlxG.save.data.opponent;
			PlayStateChangeables.mirrorMode = FlxG.save.data.mirror;
			PlayStateChangeables.holds = FlxG.save.data.sustains;
			PlayStateChangeables.healthDrain = FlxG.save.data.hdrain;
			PlayStateChangeables.healthGain = FlxG.save.data.hgain;
			PlayStateChangeables.healthLoss = FlxG.save.data.hloss;
			PlayStateChangeables.practiceMode = FlxG.save.data.practice;
			PlayStateChangeables.skillIssue = FlxG.save.data.noMisses;
		}
		else
		{
			PlayStateChangeables.modchart = true;
			PlayStateChangeables.opponentMode = false;
			PlayStateChangeables.mirrorMode = false;
			PlayStateChangeables.holds = true;
			PlayStateChangeables.healthDrain = false;
			PlayStateChangeables.healthGain = 1;
			PlayStateChangeables.healthLoss = 1;
			PlayStateChangeables.practiceMode = false;
			PlayStateChangeables.skillIssue = false;
		}

		usedBot = false;

		startTime = 0;

		// Search For Lua Modcharts
		#if (FEATURE_FILESYSTEM && FEATURE_LUAMODCHART)
		executeModchart = FileSystem.exists(Paths.lua('songs/${PlayState.SONG.songId}/modchart')) && PlayStateChangeables.modchart;
		if (isSM)
			executeModchart = FileSystem.exists(pathToSm + "/modchart.lua");
		#end
		#if !FEATURE_LUAMODCHART
		executeModchart = false;
		#end

		// Use FileSystem on desktop for cool modcharts with no compile :>

		if (FlxG.save.data.gen)
		{
			Debug.logInfo('Searching for Lua Modchart? ($executeModchart) at ${Paths.lua('songs/${PlayState.SONG.songId}/modchart')}');
			// Debug.logInfo('Searching for HScript? ($executeHScript) at ${Paths.hscript('songs/${PlayState.SONG.songId}/script')}');
		}

		if (executeModchart)
			songMultiplier = 1;

		#if FEATURE_DISCORD
		// Making difficulty text for Discord Rich Presence.
		if (!isSM)
			storyDifficultyText = CoolUtil.difficultyFromInt(storyDifficulty);
		else
			storyDifficultyText = "SM";

		iconRPC = SONG.player2;
		// To avoid having duplicate images in Discord assets
		switch (iconRPC)
		{
			case 'senpai-angry':
				iconRPC = 'senpai';
			case 'monster-christmas':
				iconRPC = 'monster';
			case 'mom-car':
				iconRPC = 'mom';
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: Week " + storyWeek;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;

		// Updating Discord Rich Presence.
		Discord.changePresence(detailsText
			+ " "
			+ SONG.songName
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"\nAcc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC);
		#end

		barImage = Paths.image('healthBar');

		// Setup The Cameras.
		camGame = new SwagCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camHUD.pixelPerfectRender = true;
		camStrums = new FlxCamera();
		camStrums.height = 1300;
		camStrums.bgColor.alpha = 0;
		overlayCam = new FlxCamera();
		overlayCam.bgColor.alpha = 0;

		// Game Camera (where stage and characters are)
		FlxG.cameras.reset(camGame);

		// HUD Camera (Health Bar, scoreTxt, etc)
		FlxG.cameras.add(camHUD, false);

		// StrumLine Camera
		FlxG.cameras.add(camStrums, false);

		FlxG.cameras.add(overlayCam, false);

		camHUD.zoom = PlayStateChangeables.zoom;
		camStrums.zoom = camHUD.zoom;

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		persistentUpdate = true;
		persistentDraw = true;

		// If A Song Doesn't Have Events, It Makes One Automatically.
		if (SONG.eventObjects == null)
		{
			SONG.eventObjects = [new Song.Event("Init BPM", 0, SONG.bpm * songMultiplier, "1", "BPM Change")];
		}

		if (SONG == null)
			SONG = Song.loadFromJson('bopeebo', '');

		// if the song has dialogue, so we don't accidentally try to load a nonexistant file and crash the game
		if (Paths.doesTextAssetExist(Paths.txt('data/songs/${PlayState.SONG.songId}/dialogue')))
		{
			dialogue = CoolUtil.coolTextFile(Paths.txt('data/songs/${PlayState.SONG.songId}/dialogue'));
		}

		if (isStoryMode)
		{
			switch (storyWeek)
			{
				case 7:
					inCinematic = true;
				case 5:
					if (PlayState.SONG.songId == 'winter-horrorland')
						inCinematic = true;
			}
		}

		// defaults if no stage was found in chart
		var stageCheck:String = 'stage';

		// If the stage isn't specified in the chart, we use the story week value.
		if (SONG.stage == null)
		{
			switch (storyWeek)
			{
				case 0 | 1:
					stageCheck = 'stage';
				case 2:
					stageCheck = 'halloween';
				case 3:
					stageCheck = 'philly';
				case 4:
					stageCheck = 'limo';
				case 5:
					if (SONG.songId == 'winter-horrorland')
					{
						stageCheck = 'mallEvil';
					}
					else
					{
						stageCheck = 'mall';
					}
				case 6:
					if (SONG.songId == 'thorns')
					{
						stageCheck = 'schoolEvil';
					}
					else
					{
						stageCheck = 'school';
					}
				case 7:
					stageCheck = 'tank';
					// i should check if its stage (but this is when none is found in chart anyway)
			}
		}
		else
		{
			stageCheck = SONG.stage;
		}

		Stage = new Stage(stageCheck);

		var directory:String = 'shared';
		var otherDir:String = Stage.stageDir;

		if (otherDir != null)
			directory = otherDir;

		Paths.setCurrentLevel(directory);

		Debug.logTrace(directory);

		Stage.initStageProperties();

		Stage.loadStageData(stageCheck);

		if (!Stage.doesExist)
		{
			Debug.logTrace('Stage Does Not Exist For ${Stage.curStage}. Loading Default Stage.');
			Stage.loadStageData('stage');
			Stage.initStageProperties();
		}

		Stage.inEditor = false;

		// pissed me off that having non existent stages just load black instead of default stage

		if (isStoryMode)
			songMultiplier = 1;

		// defaults if no gf was found in chart
		var gfCheck:String = 'gf';

		if (SONG.gfVersion == null)
		{
			switch (storyWeek)
			{
				case 4:
					gfCheck = 'gf-car';
				case 5:
					gfCheck = 'gf-christmas';
				case 6:
					gfCheck = 'gf-pixel';
				case 7:
					gfCheck = 'gfTank';
			}
		}
		else
		{
			gfCheck = SONG.gfVersion;
		}

		gfGroup = new FlxTypedGroup<Character>();
		boyfriendGroup = new FlxTypedGroup<Character>();
		dadGroup = new FlxTypedGroup<Character>();

		// Load Characters.
		if (!stageTesting)
		{
			if (Stage.hasGF)
			{
				gf = new Character(400, 130, gfCheck);

				if (gf.frames == null)
				{
					#if debug
					FlxG.log.warn(["Couldn't load gf: " + gfCheck + ". Loading default gf"]);
					#end
					gf = new Character(400, 130, 'gf');
				}
			}
			else
				gf = null;

			boyfriend = new Boyfriend(770, 450, SONG.player1);

			if (boyfriend.frames == null)
			{
				#if debug
				FlxG.log.warn(["Couldn't load boyfriend: " + SONG.player1 + ". Loading default boyfriend"]);
				#end
				boyfriend = new Boyfriend(770, 450, 'bf');
			}

			dad = new Character(100, 100, SONG.player2);

			if (dad.frames == null)
			{
				#if debug
				FlxG.log.warn(["Couldn't load opponent: " + SONG.player2 + ". Loading default opponent"]);
				#end
				dad = new Character(100, 100, 'dad');
			}
		}

		Stage.initCamPos();

		// Initialize Scripts For Real.

		var positions = Stage.positions[Stage.curStage];
		var charGroup:FlxTypedGroup<Character> = new FlxTypedGroup<Character>();

		if (gf != null)
			gfGroup.add(gf);

		dadGroup.add(dad);
		boyfriendGroup.add(boyfriend);

		for (g in gfGroup.members)
		{
			g.x += g.charPos[0];
			g.y += g.charPos[1];
			charGroup.add(g);
		}

		for (d in dadGroup.members)
		{
			d.x += d.charPos[0];
			d.y += d.charPos[1];
			charGroup.add(d);
		}

		for (b in boyfriendGroup.members)
		{
			b.x += b.charPos[0];
			b.y += b.charPos[1];
			charGroup.add(b);
		}

		if (positions != null)
		{
			for (char => pos in positions)
				for (person in charGroup.members)
					if (person.curCharacter == char)
						person.setPosition(pos[0], pos[1]);
		}

		if (FlxG.save.data.background)
		{
			for (i in Stage.toAdd)
			{
				add(i);
			}

			for (index => array in Stage.layInFront)
			{
				switch (index)
				{
					case 0:
						if (gf != null)
						{
							add(gfGroup);
							gf.scrollFactor.set(0.95, 0.95);
						}

						for (bg in array)
							add(bg);
					case 1:
						add(dadGroup);
						for (bg in array)
							add(bg);
					case 2:
						add(boyfriendGroup);
						for (bg in array)
							add(bg);
				}
			}
		}
		else
		{
			if (gf != null)
			{
				add(gfGroup);
				gf.scrollFactor.set(0.95, 0.95);
			}

			add(dadGroup);
			add(boyfriendGroup);
		}

		if (dad.hasTrail)
		{
			if (FlxG.save.data.distractions)
			{
				// trailArea.scrollFactor.set();
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				// evilTrail.changeValuesEnabled(false, false, false, false);
				// evilTrail.changeGraphic()
				add(evilTrail);
				// evilTrail.scrollFactor.set(1.1, 1.1);
			}
		}

		// Camera Positioning.
		camPos = new FlxPoint(0, 0);

		camPos.x = Stage.camPosition[0];
		camPos.y = Stage.camPosition[1];

		if (dad.replacesGF && gf != null)
		{
			if (!stageTesting)
				dad.setPosition(gf.x, gf.y);
			gf.visible = false;
			tweenCamIn();
		}

		#if FEATURE_HSCRIPT
		initScripts();

		scripts.executeAllFunc("create");
		#end

		var doof = null;

		if (isStoryMode)
		{
			doof = new DialogueBox(false, dialogue);
			doof.scrollFactor.set();
			doof.finishThing = startCountdown;
		}

		if (!isStoryMode && songMultiplier == 1)
		{
			var firstNoteTime = Math.POSITIVE_INFINITY;
			var playerTurn = false;
			for (index => section in SONG.notes)
			{
				for (note in section.sectionNotes)
				{
					if (note[0] < firstNoteTime)
					{
						firstNoteTime = note[0];
						if (note[1] > 3)
							playerTurn = true;
						else
							playerTurn = false;
					}
				}

				if (index + 1 == SONG.notes.length)
				{
					var timing = firstNoteTime;

					if (timing > 5000)
					{
						needSkip = true;
						skipTo = (timing - 1000) / songMultiplier;
					}
				}
			}
		}

		arrowLanes = new FlxTypedGroup<FlxSprite>();
		arrowLanes.camera = camHUD;

		add(arrowLanes);

		add(uiGroup = new FlxSpriteGroup());

		Conductor.songPosition = -5000;
		Conductor.rawPosition = Conductor.songPosition;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width + 50, 10, FlxColor.WHITE);
		strumLine.scrollFactor.set();

		if (PlayStateChangeables.useDownscroll)
			strumLine.y = FlxG.height - 165;

		strumLineNotes = new FlxTypedGroup<StaticArrow>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<StaticArrow>();
		cpuStrums = new FlxTypedGroup<StaticArrow>();

		switch (STYLE.style.toLowerCase())
		{
			case 'pixel':
				noteskinPixelSprite = CustomNoteHelpers.Skin.generatePixelSprite(FlxG.save.data.noteskin);
				noteskinPixelSpriteEnds = CustomNoteHelpers.Skin.generatePixelSprite(FlxG.save.data.noteskin, true);
			case 'default':
				noteskinSprite = CustomNoteHelpers.Skin.generateNoteskinSprite(FlxG.save.data.noteskin);
				cpuNoteskinSprite = CustomNoteHelpers.Skin.generateNoteskinSprite(FlxG.save.data.cpuNoteskin);
		}

		notesplashSprite = CustomNoteHelpers.Splash.generateNotesplashSprite(FlxG.save.data.notesplash, '');

		tweenBoolshit = SONG.songId != 'tutorial' && SONG.songId != 'roses';

		generateStaticArrows(0, tweenBoolshit);
		generateStaticArrows(1, tweenBoolshit);

		if (FlxG.save.data.gen)
		{
			if (SONG.songId == null)
				Debug.logInfo('SongID Is Null.');
			else
				Debug.logInfo('Succesfully Loaded ' + SONG.songName);
		}

		addMobileControls(false);

		generateSong(SONG.songId);

		#if FEATURE_LUAMODCHART
		if (executeModchart)
		{
			luaModchart = ModchartState.createModchartState();
			luaModchart.executeState('onCreate', [null]);
		}
		#end

		#if FEATURE_LUAMODCHART
		if (executeModchart)
		{
			new LuaCamera(camGame, "camGame").Register(ModchartState.lua);
			new LuaCamera(camHUD, "camHUD").Register(ModchartState.lua);
			new LuaCamera(camStrums, "camStrums").Register(ModchartState.lua);
			new LuaCharacter(dad, "dad").Register(ModchartState.lua);
			if (gf != null)
				new LuaCharacter(gf, "gf").Register(ModchartState.lua);

			new LuaCharacter(boyfriend, "boyfriend").Register(ModchartState.lua);
		}
		#end

		var index = 0;

		if (startTime != 0)
		{
			var toBeRemoved = [];
			for (i in 0...unspawnNotes.length)
			{
				var dunceNote:Note = unspawnNotes[i];

				if (dunceNote.strumTime <= startTime)
					toBeRemoved.push(dunceNote);
			}

			for (i in toBeRemoved)
				unspawnNotes.remove(i);
			if (FlxG.save.data.gen)
				Debug.logTrace("Removed " + toBeRemoved.length + " cuz of start time");
		}

		for (i in 0...unspawnNotes.length)
			if (unspawnNotes[i].strumTime < startTime)
				unspawnNotes.remove(unspawnNotes[i]);

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.05);
		FlxG.camera.zoom = Stage.camZoom;
		zoomForTweens = Stage.camZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		createBar();

		var ratingStyle = "Default";

		if (SONG.style != null)
			ratingStyle = SONG.style;

		RatingWindow.createRatings(ratingStyle);

		judgementCounter = new FlxText(20, 0, 0, "", 20);
		judgementCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		judgementCounter.borderSize = 2;
		judgementCounter.borderQuality = 2;
		judgementCounter.scrollFactor.set();
		judgementCounter.cameras = [camHUD];
		judgementCounter.screenCenter(Y);
		judgementCounter.text = 'Marvelous: ${marvs}\nSicks: ${sicks}\nGoods: ${goods}\nBads: ${bads}\nShits: ${shits}\nMisses: ${misses}';
		if (FlxG.save.data.judgementCounter)
		{
			uiGroup.add(judgementCounter);
		}

		botPlayState = new FlxText(healthBarBG.x + healthBarBG.width / 2 - 75, healthBarBG.y + (PlayStateChangeables.useDownscroll ? 100 : -100), 0,
			"BOTPLAY", 20);
		botPlayState.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botPlayState.scrollFactor.set();
		botPlayState.borderSize = 2;
		botPlayState.borderQuality = 1;
		botPlayState.alpha = 0.5;
		botPlayState.cameras = [camHUD];

		if (PlayStateChangeables.botPlay)
			uiGroup.add(botPlayState);

		addedBotplay = PlayStateChangeables.botPlay;

		iconP1 = new HealthIcon(boyfriend.healthIcon, boyfriend.iconAnimated, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);

		iconP2 = new HealthIcon(dad.healthIcon, dad.iconAnimated, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);

		if (FlxG.save.data.healthBar)
		{
			uiGroup.add(iconP1);
			uiGroup.add(iconP2);

			if (FlxG.save.data.colour)
			{
				if (!PlayStateChangeables.opponentMode)
					healthBar.createFilledBar(dad.barColor, boyfriend.barColor);
				else
					healthBar.createFilledBar(boyfriend.barColor, dad.barColor);
			}
			else
			{
				if (!PlayStateChangeables.opponentMode)
					healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
				else
					healthBar.createFilledBar(0xFF66FF33, 0xFFFF0000);
			}
		}

		scoreTxt = new FlxText(FlxG.width / 2 - 235, healthBarBG.y + 50, 0, "", 16);
		scoreTxt.screenCenter(X);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderQuality = 2;
		scoreTxt.antialiasing = true; // Should use the save data but its too annoying.
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.text = Ratings.CalculateRanking(songScore, songScoreDef, nps, maxNPS, accuracy);
		if (!FlxG.save.data.healthBar)
			scoreTxt.y = healthBarBG.y;

		uiGroup.add(scoreTxt);

		if (iconP2.animOffsets.exists('Idle'))
		{
			icon2AnimArray[0] = true;
		}
		if (iconP2.animOffsets.exists('Lose'))
		{
			icon2AnimArray[1] = true;
		}

		if (iconP1.animOffsets.exists('Idle'))
		{
			icon1AnimArray[0] = true;
		}
		if (iconP1.animOffsets.exists('Lose'))
		{
			icon1AnimArray[1] = true;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, '', 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.00001;

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];

		uiGroup.cameras = [camHUD];
		rating.cameras = [camHUD];
		currentTimingShown.cameras = [camHUD];
		// sfjl

		if (isStoryMode)
			doof.cameras = [camHUD];

		startingSong = true;
		for (da in dadGroup.members)
			da.dance();

		for (boi in boyfriendGroup.members)
			boi.dance();

		for (goil in gfGroup.members)
			goil.dance();

		cacheCountdown();

		if (inCutscene)
			removeStaticArrows(true);

		if (isStoryMode)
		{
			switch (StringTools.replace(curSong, " ", "-").toLowerCase())
			{
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					camStrums.visible = false;
					removeStaticArrows();

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(1, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							createTween(FlxG.camera, {zoom: Stage.camZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
									camHUD.visible = true;
									camStrums.visible = true;
								}
							});
						});
					});
				case 'senpai':
					schoolIntro(doof);
				case 'roses':
					FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
				case 'thorns':
					schoolIntro(doof);
				case 'ugh', 'guns', 'stress':
					#if VIDEOS
					playCutscene('${SONG.songId.toLowerCase()}Cutscene.mp4', false);
					#end
				default:
					createTimer(0.5, function(timer)
					{
						startCountdown();
					});
			}
		}
		else
		{
			createTimer(0.5, function(timer)
			{
				startCountdown();
			});
		}

		var styleShit:String = (STYLE.style == null ? 'default' : STYLE.style).toLowerCase();
		for (i in 1...3)
		{
			precacheThing('styles/$styleShit/missnote$i', 'sound', 'shared');
		}

		// This allow arrow key to be detected by flixel. See https://github.com/HaxeFlixel/flixel/issues/2190
		FlxG.keys.preventDefaultKeys = [];

		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, handleInput);
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, releaseInput);

		super.create();

		if (FlxG.save.data.distractions && FlxG.save.data.background)
		{
			if (Stage.curStage == 'tank' && gf != null && gf.curCharacter == 'pico-speaker')
			{
				if (FlxG.save.data.distractions)
				{
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(20, 1500, true);
					firstTank.strumTime = 10;
					if (Stage.swagBacks['tankmanRun'] != null)
					{
						Stage.swagBacks['tankmanRun'].add(firstTank);

						for (i in 0...TankmenBG.animationNotes.length)
						{
							if (FlxG.random.bool(16))
							{
								var tankBih = Stage.swagBacks['tankmanRun'].recycle(TankmenBG);
								tankBih.strumTime = TankmenBG.animationNotes[i].strumTime;
								tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i].noteData < 2);
								Stage.swagBacks['tankmanRun'].add(tankBih);
							}
						}
					}
				}
			}
		}

		if (PlayStateChangeables.skillIssue)
		{
			var redVignette:FlxSprite = new FlxSprite().loadGraphic(Paths.image('nomisses_vignette'));
			redVignette.screenCenter();
			redVignette.cameras = [overlayCam];
			add(redVignette);
		}

		if (!isStoryMode)
			tankIntroEnd = true;

		precacheThing('alphabet', 'image', null);

		precacheThing('breakfast', 'music');

		if (FlxG.save.data.hitSound != 0)
			precacheThing("hitsounds/" + HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase(), 'sound', 'shared');

		cachePopUpScore();

		if (isStoryMode)
			initStoryLength = StoryMenuState.weekData()[storyWeek].songs.length;

		if (FlxG.save.data.showMs)
		{
			insert(PlayState.instance.members.indexOf(notes), currentTimingShown);
			currentTimingShown.alpha = 0;
		}

		if (FlxG.save.data.showRating)
		{
			insert(PlayState.instance.members.indexOf(notes), rating);
			rating.alpha = 0;
		}

		subStates.push(new PauseSubState());
		subStates.push(new ResultsScreen());
		subStates.push(new GameOverSubstate());
		subStates.push(new OptionsMenu(true));

		#if FEATURE_LUAMODCHART
		if (executeModchart)
		{
			luaModchart.executeState('onCreatePost', [null]);
		}
		#end

		#if FEATURE_HSCRIPT
		scripts.executeAllFunc("createPost");
		#end

		Paths.clearUnusedMemory();

		Debug.logTrace("Took " + Std.string(FlxMath.roundDecimal(haxe.Timer.stamp() - stamp, 3)) + " Seconds To Load.");
	}

	function createBar()
	{
		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(barImage);
		if (PlayStateChangeables.useDownscroll)
			healthBarBG.y = 50;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.antialiasing = FlxG.save.data.antialiasing;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, PlayStateChangeables.opponentMode ? LEFT_TO_RIGHT : RIGHT_TO_LEFT,
			Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this, 'shownHealth', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.antialiasing = FlxG.save.data.antialiasing;

		if (FlxG.save.data.healthBar)
		{
			uiGroup.add(healthBarBG);
			uiGroup.add(healthBar);
		}

		// This Function Makes It Easier To Change HealthBar Styles And Shit.
	}

	public var tankIntroEnd:Bool = false;

	/*
		function tankIntro()
		{
			dad.visible = false;
			precacheThing('DISTORTO', 'music', 'week7');
			var tankManEnd:Void->Void = function()
			{
				tankIntroEnd = true;
				var timeForStuff:Float = Conductor.crochet / 1000 * 5;
				createTween(FlxG.camera, {zoom: Stage.camZoom}, timeForStuff, {ease: FlxEase.quadInOut});
				startCountdown();
				camStrums.visible = true;
				camHUD.visible = true;
				dad.visible = true;
				FlxG.sound.music.stop();

				var cutSceneStuff:Array<FlxSprite> = [Stage.swagBacks['tankman']];
				if (SONG.songId == 'stress' && !FlxG.save.data.stressMP4)
				{
					cutSceneStuff.push(Stage.swagBacks['bfCutscene']);
					cutSceneStuff.push(Stage.swagBacks['gfCutscene']);
				}
				for (char in cutSceneStuff)
				{
					char.kill();
					remove(char);
					char.destroy();
				}
				Paths.clearUnusedMemory();
				Paths.runGC();
			}

			switch (SONG.songId)
			{
				case 'ugh':
					removeStaticArrows();
					camHUD.visible = false;
					precacheThing('wellWellWell', 'sound', 'week7');
					precacheThing('killYou', 'sound', 'week7');
					precacheThing('bfBeep', 'sound', 'week7');
					var WellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell', 'week7'));

					FlxG.sound.list.add(WellWellWell);

					FlxG.sound.playMusic(Paths.music('DISTORTO', 'week7'));
					FlxG.sound.music.fadeIn();
					Stage.swagBacks['tankman'].animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
					Stage.swagBacks['tankman'].animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
					Stage.swagBacks['tankman'].animation.play('wellWell', true);
					FlxG.camera.zoom *= 1.2;
					camFollow.x = 436.5;
					camFollow.y = 500;

					// Well well well, what do we got here?
					createTimer(0.1, function(tmr:FlxTimer)
					{
						WellWellWell.play(true);
					});

					// Move camera to BF
					createTimer(3, function(tmr:FlxTimer)
					{
						camFollow.x += 400;
						camFollow.y += 60;
						// Beep!
						createTimer(1.5, function(tmr:FlxTimer)
						{
							boyfriend.playAnim('singUP', true);
							FlxG.sound.play(Paths.sound('bfBeep'));
						});

						// Move camera to Tankman
						createTimer(3, function(tmr:FlxTimer)
						{
							camFollow.x = 436.5;
							camFollow.y = 500;
							boyfriend.dance();
							Stage.swagBacks['tankman'].animation.play('killYou', true);
							FlxG.sound.play(Paths.sound('killYou'));

							createTimer(6.1, function(tmr:FlxTimer)
							{
								tankManEnd();
							});
						});
					});

				case 'guns':
					precacheThing('tankSong2', 'sound', 'week7');
					FlxG.sound.playMusic(Paths.music('DISTORTO', 'week7'), 0, false);
					FlxG.sound.music.fadeIn();

					var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2', 'week7'));
					FlxG.sound.list.add(tightBars);

					laneunderlayOpponent.alpha = FlxG.save.data.laneTransparency;
					laneunderlay.alpha = FlxG.save.data.laneTransparency;

					createTimer(0.01, function(tmr:FlxTimer)
					{
						tightBars.play(true);
					});

					createTimer(0.5, function(tmr:FlxTimer)
					{
						createTween(camStrums, {alpha: 0}, 1.5, {ease: FlxEase.quadInOut});
						createTween(camHUD, {alpha: 0}, 1.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								camHUD.visible = false;
								camHUD.alpha = 1;
								camStrums.visible = false;
								camStrums.alpha = 1;
								removeStaticArrows();
								laneunderlayOpponent.alpha = 0;
								laneunderlay.alpha = 0;
							}
						});
					});

					Stage.swagBacks['tankman'].animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
					Stage.swagBacks['tankman'].animation.play('tightBars', true);
					boyfriend.animation.curAnim.finish();

					createTimer(1, function(tmr:FlxTimer)
					{
						camFollow.x = 436.5;
						camFollow.y = 520;
					});

					createTimer(4, function(tmr:FlxTimer)
					{
						camFollow.y -= 150;
						camFollow.x += 100;
					});
					createTimer(1, function(tmr:FlxTimer)
					{
						createTween(FlxG.camera, {zoom: Stage.camZoom * 1.2}, 3, {ease: FlxEase.quadInOut});

						createTween(FlxG.camera, {zoom: Stage.camZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 3});
						createTween(FlxG.camera, {zoom: Stage.camZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 3.5});
					});

					createTimer(4, function(tmr:FlxTimer)
					{
						gf.playAnim('sad', true);
						gf.animation.finishCallback = function(name:String)
						{
							gf.playAnim('sad', true);
						};
					});

					createTimer(11.6, function(tmr:FlxTimer)
					{
						camFollow.x = 440;
						camFollow.y = 534.5;
						tankManEnd();

						gf.dance();
						gf.animation.finishCallback = null;
					});

				case 'stress':
					if (!FlxG.save.data.stressMP4)
					{
						laneunderlayOpponent.alpha = FlxG.save.data.laneTransparency;
						laneunderlay.alpha = FlxG.save.data.laneTransparency;
						precacheThing('stressCutscene', 'sound', 'week7');

						precacheThing('cutscenes/stress2', 'image', 'week7');

						createTimer(0.5, function(tmr:FlxTimer)
						{
							createTween(camStrums, {alpha: 0}, 1.5, {ease: FlxEase.quadInOut});
							createTween(camHUD, {alpha: 0}, 1.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									camHUD.visible = false;
									camHUD.alpha = 1;
									camStrums.visible = false;
									camStrums.alpha = 1;
									removeStaticArrows();
									laneunderlayOpponent.alpha = 0;
									laneunderlay.alpha = 0;
								}
							});
						});

						gf.visible = false;
						boyfriend.visible = false;
						createTimer(1, function(tmr:FlxTimer)
						{
							camFollow.x = 436.5;
							camFollow.y = 534.5;
							createTween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
						});

						Stage.swagBacks['bfCutscene'].animation.finishCallback = function(name:String)
						{
							Stage.swagBacks['bfCutscene'].animation.play('idle');
						}

						Stage.swagBacks['dummyGf'].animation.finishCallback = function(name:String)
						{
							Stage.swagBacks['dummyGf'].animation.play('idle');
						}

						var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
						FlxG.sound.list.add(cutsceneSnd);

						Stage.swagBacks['tankman'].animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
						Stage.swagBacks['tankman'].animation.play('godEffingDamnIt', true);

						createTimer(0.01, function(tmr:FlxTimer) // Fixes sync????
						{
							cutsceneSnd.play(true);
						});

						createTimer(14.2, function(tmr:FlxTimer)
						{
							Stage.swagBacks['bfCutscene'].animation.finishCallback = null;
							Stage.swagBacks['dummyGf'].animation.finishCallback = null;
						});

						createTimer(15.2, function(tmr:FlxTimer)
						{
							createTween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
							createTween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});
							createTimer(2.3, function(tmr:FlxTimer)
							{
								camFollow.x = 630;
								camFollow.y = 425;
								FlxG.camera.zoom = 0.9;
							});

							Stage.swagBacks['dummyGf'].visible = false;
							Stage.swagBacks['gfCutscene'].visible = true;
							Stage.swagBacks['gfCutscene'].animation.play('dieBitch', true);
							Stage.swagBacks['gfCutscene'].animation.finishCallback = function(name:String)
							{
								if (name == 'dieBitch') // Next part
								{
									Stage.swagBacks['gfCutscene'].animation.play('getRektLmao', true);
									Stage.swagBacks['gfCutscene'].offset.set(224, 445);
								}
								else
								{
									Stage.swagBacks['gfCutscene'].visible = false;
									Stage.swagBacks['picoCutscene'].visible = true;
									Stage.swagBacks['picoCutscene'].animation.play('anim', true);

									boyfriend.visible = true;
									Stage.swagBacks['bfCutscene'].visible = false;
									boyfriend.playAnim('bfCatch', true);
									boyfriend.animation.finishCallback = function(name:String)
									{
										if (name != 'idle')
										{
											boyfriend.playAnim('idle', true);
											boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
										}
									};

									Stage.swagBacks['picoCutscene'].animation.finishCallback = function(name:String)
									{
										Stage.swagBacks['picoCutscene'].visible = false;
										gf.visible = true;
										Stage.swagBacks['picoCutscene'].animation.finishCallback = null;
									};
									Stage.swagBacks['gfCutscene'].animation.finishCallback = null;
								}
							};
						});

						createTimer(19.5, function(tmr:FlxTimer)
						{
							Stage.swagBacks['tankman'].frames = Paths.getSparrowAtlas('cutscenes/stress2', 'week7');
							Stage.swagBacks['tankman'].animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
							Stage.swagBacks['tankman'].animation.play('lookWhoItIs', true);
							Stage.swagBacks['tankman'].x += 90;
							Stage.swagBacks['tankman'].y += 6;

							createTimer(0.5, function(tmr:FlxTimer)
							{
								camFollow.x = 436.5;
								camFollow.y = 534.5;
							});
						});

						createTimer(31.2, function(tmr:FlxTimer)
						{
							boyfriend.playAnim('singUPmiss', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if (name == 'singUPmiss')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
								}
							};

							camFollow.setPosition(1100, 625);
							FlxG.camera.zoom = 1.3;

							createTimer(1, function(tmr:FlxTimer)
							{
								FlxG.camera.zoom = 0.9;
								camFollow.setPosition(440, 534.5);
							});
						});
						createTimer(35.5, function(tmr:FlxTimer)
						{
							tankManEnd();
							boyfriend.animation.finishCallback = null;
						});
					}
			}
		}

		public function addShaderToCamera(camera:String, effect:ShaderEffect)
		{
			switch (camera.toLowerCase())
			{
				case 'camhud' | 'hud':
					camHUDShaders.push(effect);
					var newCamEffects:Array<BitmapFilter> = [];
					for (i in camHUDShaders)
						newCamEffects.push(new ShaderFilter(i.shader));
					camHUD.setFilters(newCamEffects);
				case 'camgame' | 'game':
					camGameShaders.push(effect);
					var newCamEffects:Array<BitmapFilter> = [];
					for (i in camGameShaders)
						newCamEffects.push(new ShaderFilter(i.shader));
					camGame.setFilters(newCamEffects);
				case 'camstrums' | 'strums':
					camStrumsShaders.push(effect);
					var newCamEffects:Array<BitmapFilter> = [];
					for (i in camStrumsShaders)
						newCamEffects.push(new ShaderFilter(i.shader));
					camStrums.setFilters(newCamEffects);
				case 'overlay' | 'camoverlay':
					overlayShaders.push(effect);
					var newCamEffects:Array<BitmapFilter> = [];
					for (i in overlayShaders)
						newCamEffects.push(new ShaderFilter(i.shader));
					overlayCam.setFilters(newCamEffects);
			}
		}
	 */
	public function clearShaderFromCamera(camera:String)
	{
		switch (camera.toLowerCase())
		{
			case 'camhud' | 'hud':
				camHUDShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camHUD.setFilters(newCamEffects);
			case 'camgame' | 'game':
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camGame.setFilters(newCamEffects);
			case 'overlay' | 'overlaycam':
				overlayShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				overlayCam.setFilters(newCamEffects);
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();
		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.antialiasing = false;
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();

		if (PlayState.SONG.songId == 'roses' || PlayState.SONG.songId == 'thorns')
		{
			remove(black);

			if (PlayState.SONG.songId == 'thorns')
			{
				add(red);
				camStrums.visible = false;
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (PlayState.SONG.songId == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camStrums.visible = true;
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var luaWiggles:Array<WiggleEffect> = [];

	#if FEATURE_LUAMODCHART
	public static var luaModchart:ModchartState = null;
	#end

	function set_scrollSpeed(value:Float):Float // STOLEN FROM PSYCH ENGINE ONLY SPRITE SCALING PART.
	{
		// speedChanged = true;
		if (generatedMusic)
		{
			var ratio:Float = value / scrollSpeed;
			for (note in notes)
			{
				if (note.animation.curAnim != null)
					if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
					{
						note.scale.y *= ratio;
						note.updateHitbox();
					}
			}
			for (note in unspawnNotes)
			{
				if (note.animation.curAnim != null)
					if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
					{
						note.scale.y *= ratio;
						note.updateHitbox();
					}
			}
		}
		scrollSpeed = value;
		return value;
	}

	function startCountdown():Void
	{
		if (inCinematic || inCutscene)
		{
			if (!arrowsGenerated)
			{
				generateStaticArrows(1, true);

				generateStaticArrows(0, true);
			}
		}

		#if FEATURE_HSCRIPT
		if (ScriptUtil.hasPause(scripts.executeAllFunc("startCountdown")))
			return;
		#end

		inCinematic = false;
		inCutscene = false;

		startedCountdown = mobileControls.visible = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		if (inst.playing)
			inst.stop();
		if (vocals != null && !SONG.splitVoiceTracks)
			vocals.stop();
		if ((vocalsPlayer != null && vocalsEnemy != null) && SONG.splitVoiceTracks)
		{
			vocalsPlayer.stop();
			vocalsEnemy.stop();
		}

		var swagCounter:Int = 0;

		startTimer = createTimer((Conductor.crochet / 1000), function(tmr:FlxTimer)
		{
			// this just based on beatHit stuff but compact
			if (allowedToHeadbang && swagCounter % gfSpeed == 0 && gf != null)
			{
				for (g in gfGroup.members)
					g.dance();
			}

			if (swagCounter % Math.floor(idleBeat * songMultiplier) == 0)
			{
				for (b in boyfriendGroup.members)
				{
					if (b != null && idleToBeat && !b.animation.curAnim.name.endsWith("miss"))
						b.dance(forcedToIdle);
				}
				for (d in dadGroup.members)
				{
					if (d != null && idleToBeat)
						d.dance(forcedToIdle);
				}
			}
			else if (swagCounter % Math.floor(idleBeat * songMultiplier) != 0)
			{
				for (b in boyfriendGroup.members)
				{
					if (b != null && b.isDancing && !b.animation.curAnim.name.endsWith("miss"))
						b.dance();
				}
				for (d in dadGroup.members)
				{
					if (d != null && d.isDancing)
						d.dance();
				}
			}
			var styleShit:String = (STYLE.style == null ? 'default' : STYLE.style).toLowerCase();
			var introAlts = ['hud/$styleShit/ready', 'hud/$styleShit/set', 'hud/$styleShit/go'];

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('styles/$styleShit/intro3'), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.scrollFactor.set();
					ready.scale.set(0.7, 0.7);
					ready.cameras = [camHUD];
					ready.updateHitbox();

					if (STYLE.antialiasing == false)
						ready.antialiasing = false;

					ready.setGraphicSize(Std.int(ready.width * STYLE.scale));

					ready.screenCenter();
					add(ready);
					createTween(ready, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('styles/$styleShit/intro2'), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.scrollFactor.set();
					set.scale.set(0.7, 0.7);
					set.setGraphicSize(Std.int(set.width * STYLE.scale));
					set.cameras = [camHUD];
					set.screenCenter();
					if (STYLE.antialiasing == false)
						set.antialiasing = false;
					add(set);
					createTween(set, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('styles/$styleShit/intro1'), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.scrollFactor.set();
					go.scale.set(0.7, 0.7);
					go.cameras = [camHUD];
					go.setGraphicSize(Std.int(go.width * STYLE.scale));
					if (STYLE.antialiasing == false)
						go.antialiasing = false;

					go.updateHitbox();

					go.screenCenter();
					add(go);
					createTween(go, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('styles/$styleShit/introGo'), 0.6);
			}
			#if FEATURE_HSCRIPT
			scripts.executeAllFunc("countTick", [swagCounter]);
			#end

			swagCounter += 1;
		}, 4);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	private function getKey(charCode:Int):String
	{
		for (key => value in FlxKey.fromStringMap)
		{
			if (charCode == value)
				return key;
		}
		return null;
	}

	var keys = [false, false, false, false];
	var binds:Array<String> = [
		FlxG.save.data.leftBind,
		FlxG.save.data.downBind,
		FlxG.save.data.upBind,
		FlxG.save.data.rightBind
	];

	private function releaseInput(evt:KeyboardEvent):Void // handles releases
	{
		if (PlayStateChangeables.botPlay)
			return;

		@:privateAccess
		var key = FlxKey.toStringMap.get(evt.keyCode);

		var data = -1;

		data = getKeyFromKeyCode(evt.keyCode);

		switch (evt.keyCode) // arrow keys
		{
			case 37:
				data = 0;
			case 40:
				data = 1;
			case 38:
				data = 2;
			case 39:
				data = 3;
		}

		if (data == -1)
			return;

		keys[data] = false;

		if (songStarted && !paused)
			keyShit();
	}

	public var closestNotes:Array<Note> = [];

	private function getKeyFromKeyCode(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...binds.length)
			{
				if (key == binds[i])
				{
					return i;
				}
			}
		}
		return -1;
	}

	private function handleInput(evt:KeyboardEvent):Void
	{ // this actually handles press inputs

		if (PlayStateChangeables.botPlay || paused)
			return;

		// first convert it from openfl to a flixel key code
		// then use FlxKey to get the key's name based off of the FlxKey dictionary
		// this makes it work for special characters

		if (FlxG.keys.checkStatus(evt.keyCode, JUST_PRESSED))
		{
			var lastConductorTime:Float = Conductor.songPosition;

			Conductor.songPosition = lastConductorTime;

			@:privateAccess
			var key = FlxKey.toStringMap.get(evt.keyCode);

			var data = -1;

			data = getKeyFromKeyCode(evt.keyCode);

			switch (evt.keyCode) // arrow keys
			{
				case 37:
					data = 0;
				case 40:
					data = 1;
				case 38:
					data = 2;
				case 39:
					data = 3;
			}

			if (data == -1)
			{
				return;
			}
			if (keys[data])
			{
				return;
			}

			keys[data] = true;

			var closestNotes:Array<Note> = notes.members.filter(function(aliveNote:Note)
			{
				return aliveNote != null && aliveNote.alive && aliveNote.canBeHit && aliveNote.mustPress && !aliveNote.wasGoodHit
					&& !aliveNote.isSustainNote && aliveNote.noteData == data;
			});

			var defNotes:Array<Note> = [for (v in closestNotes) v];

			haxe.ds.ArraySort.sort(defNotes, sortByShit);

			if (closestNotes.length != 0)
			{
				var coolNote = null;
				coolNote = defNotes[0];

				if (defNotes.length > 1) // stacked notes or really close ones
				{
					for (i in 0...defNotes.length)
					{
						if (i == 0) // skip the first note
							continue;

						var note = defNotes[i];

						if (!note.isSustainNote && ((note.strumTime - coolNote.strumTime) < 2) && note.noteData == data)
						{
							trace('found a stacked/really close note ' + (note.strumTime - coolNote.strumTime));
							// just fuckin remove it since it's a stacked note and shouldn't be there
							destroyNote(note);
						}
					}
				}

				goodNoteHit(coolNote);
			}
			else if (!FlxG.save.data.ghost && songStarted)
			{
				noteMissPress(data);
			}

			if (songStarted && !inCutscene && !paused)
				keyShit();
		}
	}

	private function handleHolds(note:Note)
	{
		// HOLDS, check for sustain notes
		if (keys.contains(true) && generatedMusic)
		{
			goodNoteHit(note);
		}
	}

	private function handleBotplay(note:Note)
	{
		if (note.mustPress && Conductor.songPosition >= note.strumTime && note.botplayHit)
		{
			// Force good note hit regardless if it's too late to hit it or not as a fail safe

			goodNoteHit(note);
		}
	}

	private function charactersDance()
	{
		for (b in boyfriendGroup.members)
		{
			if (b.holdTimer >= Conductor.stepCrochet * 4 * 0.001)
			{
				if (b.animation.curAnim.name.startsWith('sing')
					&& !b.animation.curAnim.name.endsWith('miss')
					&& (b.animation.curAnim.curFrame >= 10 || b.animation.curAnim.finished))
					b.dance();
			}
		}

		if (PlayStateChangeables.opponentMode)
		{
			for (d in dadGroup.members)
			{
				if (d.holdTimer > Conductor.stepCrochet * 4 * 0.001 * d.holdLength * 0.5)
				{
					if (d.animation.curAnim.name.startsWith('sing')

						&& !d.animation.curAnim.name.endsWith('miss')
						&& (d.animation.curAnim.curFrame >= 10 || d.animation.curAnim.finished))
					{
						d.dance();
					}
				}
			}
		}
	}

	// sadly stolen from Psych. Im sorry :(((
	function noteMissPress(direction:Int = 1):Void
	{
		if (FlxG.save.data.ghost)
			return;

		health -= 0.08 * PlayStateChangeables.healthLoss;

		if (PlayStateChangeables.skillIssue)
			health = 0;
		if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
		{
			gf.playAnim('sad');
		}
		combo = 0;

		songScore -= 10;
		if (!endingSong)
		{
			misses++;
		}
		totalNotesHit -= 1;
		totalPlayed += 1;

		if (FlxG.save.data.missSounds)
		{
			var styleShit:String = (STYLE.style == null ? 'default' : STYLE.style).toLowerCase();
			FlxG.sound.play(Paths.soundRandom('styles/$styleShit/missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		}
		boyfriend.playAnim('sing' + dataSuffix[direction] + 'miss', true);
		if (!SONG.splitVoiceTracks)
			vocals.volume = 0;
		else
		{
			vocalsPlayer.volume = 0;
		}
		updateAccuracy();
		updateScoreText();

		#if FEATURE_HSCRIPT
		scripts.executeAllFunc("ghostTap", [direction]);
		#end
	}

	public var songStarted = false;

	public var doAnything = false;

	public var bar:FlxSprite;

	function startSong():Void
	{
		startingSong = false;
		songStarted = true;
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		addSongTiming();

		#if FEATURE_HSCRIPT
		if (ScriptUtil.hasPause(scripts.executeAllFunc("startSong")))
			return;
		#end

		inst.play();
		// FlxG.sound.music.play();
		if (!SONG.splitVoiceTracks)
			vocals.play();
		else
		{
			vocalsPlayer.play();
			vocalsEnemy.play();
		}

		songLength = ((inst.length / songMultiplier) / 1000);

		if (allowedToHeadbang && gf != null)
		{
			for (g in gfGroup.members)
			{
				g.dance();
			}
		}

		for (b in boyfriendGroup.members)
		{
			if (idleToBeat && !b.animation.curAnim.name.startsWith("sing"))
				b.dance(forcedToIdle);
		}

		for (d in dadGroup.members)
		{
			if (idleToBeat && !d.animation.curAnim.name.startsWith("sing") && !PlayStateChangeables.opponentMode)
				d.dance(forcedToIdle);
		}

		// Song check real quick
		switch (SONG.songId)
		{
			case 'bopeebo' | 'philly' | 'blammed' | 'cocoa' | 'eggnog':
				allowedToCheer = true;
			default:
				allowedToCheer = false;
		}

		switch (curSong)
		{
			case 'Bopeebo' | 'Philly Nice' | 'Blammed' | 'Cocoa' | 'Eggnog':
				allowedToCheer = true;
			default:
				allowedToCheer = false;
		}

		#if FEATURE_LUAMODCHART
		if (executeModchart)
			luaModchart.executeState("onSongStart", [null]);
		#end

		if (inst != null)
			inst.time = startTime;
		if (!SONG.splitVoiceTracks)
		{
			if (vocals != null)
				vocals.time = startTime;
		}
		else
		{
			if (vocalsPlayer != null && vocalsEnemy != null)
			{
				vocalsPlayer.time = startTime;
				vocalsEnemy.time = startTime;
			}
		}
		Conductor.songPosition = startTime;
		startTime = 0;

		recalculateAllSectionTimes();

		#if FEATURE_DISCORD
		// Updating Discord Rich Presence (with Time Left)
		Discord.changePresence(detailsText
			+ " "
			+ SONG.songName
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"\nAcc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC);
		#end

		songPosBG = new FlxSprite(0, FlxG.height - 710).loadGraphic(Paths.image('healthBar'));

		if (PlayStateChangeables.useDownscroll)
			songPosBG.y = FlxG.height - 37;

		songPosBG.screenCenter(X);
		songPosBG.scrollFactor.set();
		songPosBar = new FlxBar(640 - (Std.int(songPosBG.width - 100) / 2), songPosBG.y + 4, LEFT_TO_RIGHT, Std.int(songPosBG.width - 100),
			Std.int(songPosBG.height + 6), this, 'songPositionBar', 0, songLength);
		songPosBar.alpha = 0;
		songPosBar.scrollFactor.set();
		songPosBar.createFilledBar(FlxColor.BLACK, dad.barColor);
		songPosBar.numDivisions = 200;
		uiGroup.add(songPosBar);

		bar = new FlxSprite(songPosBar.x, songPosBar.y).makeGraphic(Math.floor(songPosBar.width), Math.floor(songPosBar.height), FlxColor.TRANSPARENT);
		bar.alpha = 0;
		uiGroup.add(bar);

		FlxSpriteUtil.drawRect(bar, 0, 0, songPosBar.width, songPosBar.height, FlxColor.TRANSPARENT,
			{thickness: 4, color: (!FlxG.save.data.background ? FlxColor.WHITE : FlxColor.BLACK)});

		songPosBG.width = songPosBar.width;

		songName = new FlxText(songPosBG.x + (songPosBG.width / 2) - (SONG.songName.length * 5), songPosBG.y - 15, 0, SONG.songName, 16);
		songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songName.scrollFactor.set();

		songName.text = SONG.songName + ' (' + FlxStringUtil.formatTime(songLength, false) + ')';
		songName.y = songPosBG.y + (songPosBG.height / 3);
		songName.alpha = 0;
		songName.visible = FlxG.save.data.songPosition;
		uiGroup.add(songName);

		songName.screenCenter(X);

		songName.visible = FlxG.save.data.songPosition;
		songPosBar.visible = FlxG.save.data.songPosition;
		bar.visible = FlxG.save.data.songPosition;

		if (FlxG.save.data.songPosition)
		{
			createTween(songName, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			createTween(songPosBar, {alpha: 0.85}, 0.5, {ease: FlxEase.circOut});
			createTween(bar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		}

		if (needSkip)
		{
			skipActive = true;
			skipText = new Alphabet(0, 550, "Press Space To Skip Intro.", true);
			skipText.setScale(0.5, 0.5);
			skipText.changeX = false;
			skipText.changeY = false;
			if (PlayStateChangeables.useDownscroll)
				skipText.y = 150;
			skipText.snapToPosition();
			skipText.screenCenter(X);
			skipText.alpha = 0;
			createTween(skipText, {alpha: 1}, 0.2);
			skipText.cameras = [camHUD];
			add(skipText);
		}
	}

	var debugNum:Int = 0;

	public var playerNotes = 0;

	var songNotesCount = 0;

	var opponentNotes = 0;

	public function generateSong(dataPath:String):Void
	{
		var chartStamp = haxe.Timer.stamp();
		var songData = SONG;
		try
		{
			if (!SONG.splitVoiceTracks)
			{
				if (SONG.needsVoices)
					vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.audioFile));
				else
					vocals = new FlxSound();
				if (FlxG.save.data.gen)
					trace('loaded vocals');

				FlxG.sound.list.add(vocals);
				vocals.play();
				vocals.pause();
			}
			else
			{
				if (SONG.needsVoices)
				{
					vocalsPlayer = new FlxSound().loadEmbedded(Paths.voices(SONG.audioFile, 'P'));
					vocalsEnemy = new FlxSound().loadEmbedded(Paths.voices(SONG.audioFile, 'E'));
				}
				else
				{
					vocalsEnemy = new FlxSound();
					vocalsPlayer = new FlxSound();
				}

				if (FlxG.save.data.gen)
					trace('loaded vocals');

				FlxG.sound.list.add(vocalsPlayer);
				FlxG.sound.list.add(vocalsEnemy);
				vocalsPlayer.play();
				vocalsPlayer.pause();
				vocalsEnemy.play();
				vocalsEnemy.pause();
			}
		}

		if (!isStoryMode && isSM)
		{
			#if FEATURE_STEPMANIA
			var bytes = File.getBytes(pathToSm + "/" + sm.header.MUSIC);
			var sound = new Sound();
			sound.loadCompressedDataFromByteArray(bytes.getData(), bytes.length);
			inst = new FlxSound().loadEmbedded(sound);
			#end
		}
		else
		{
			inst = new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.audioFile));
		}
		inst.play();
		inst.pause();

		FlxG.sound.list.add(inst);

		activeSong = SONG;
		curSong = songData.songId;

		Conductor.changeBPM(SONG.bpm);

		addSongTiming();

		fakeCrochet = Conductor.crochet;
		fakeNoteStepCrochet = fakeCrochet / 4;

		#if FEATURE_HSCRIPT
		scripts.setAll("bpm", Conductor.bpm);
		#end

		add(grpNoteSplashes);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0;

		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = (songNotes[0] - FlxG.save.data.offset - SONG.offset) / songMultiplier;
				if (daStrumTime < 0)
					daStrumTime = 0;
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var daNoteType:String = songNotes[4];
				var daBeat = TimingStruct.getBeatFromTime(daStrumTime);

				var gottaHitNote:Bool = false;

				if (songNotes[1] > 3)
					gottaHitNote = true;
				else if (songNotes[1] <= 3)
					gottaHitNote = false;

				if (PlayStateChangeables.opponentMode)
					gottaHitNote = !gottaHitNote;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote = new Note(daStrumTime, daNoteData, oldNote, false, false, gottaHitNote, daBeat);
				swagNote.noteShit = daNoteType;

				if (PlayStateChangeables.holds)
				{
					swagNote.sustainLength = songNotes[2] / songMultiplier;
				}
				else
				{
					swagNote.sustainLength = 0;
				}

				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				var anotherCrochet:Float = Conductor.crochet;
				var anotherStepCrochet:Float = anotherCrochet / 4;
				susLength = susLength / anotherStepCrochet;

				unspawnNotes.push(swagNote);

				var type = 0;

				if (susLength > 0)
				{
					swagNote.isParent = true;
					for (susNote in 0...Std.int(Math.max(susLength, 2)))
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote = new Note(daStrumTime + (anotherStepCrochet * susNote) + anotherStepCrochet, daNoteData, oldNote, true, false,
							gottaHitNote, 0);

						sustainNote.noteShit = daNoteType;

						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);

						sustainNote.mustPress = gottaHitNote;

						sustainNote.parent = swagNote;
						swagNote.children.push(sustainNote);
						sustainNote.spotInLine = type;
						type++;
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress && !swagNote.isSustainNote)
					playerNotes++;
				else if (!swagNote.mustPress)
					opponentNotes++;

				songNotesCount++;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
			}
			daBeats += 1;
		}

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
		if (FlxG.save.data.gen)
			Debug.logInfo('Generated Chart With A Time Of ' + Std.string(FlxMath.roundDecimal(haxe.Timer.stamp() - chartStamp, 3)) + " Seconds.");
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public function spawnNoteSplash(x:Float, y:Float, note:Note)
	{
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.noteType = note.noteShit;
		splash.setupNoteSplash(x, y, note);
		grpNoteSplashes.add(splash);
	}

	function spawnNoteSplashOnNote(note:Note)
	{
		var strum:StaticArrow = playerStrums.members[note.noteData];
		if (!note.mustPress)
			strum = cpuStrums.members[note.noteData];
		if (strum != null)
		{
			spawnNoteSplash(strum.x, strum.y, note);
		}
	}

	private function generateStaticArrows(player:Int, ?tween:Bool = true):Void
	{
		var seX:Float = !PlayStateChangeables.opponentMode ? (PlayStateChangeables.middleScroll ? -278 : 42) : (PlayStateChangeables.middleScroll ? 366 : 42);
		var seY:Float = strumLine.y;
		for (i in 0...4)
		{
			var babyArrow:StaticArrow = new StaticArrow(seX, seY, player, i);

			var noteTypeCheck:String = 'normal';
			babyArrow.downScroll = PlayStateChangeables.useDownscroll;

			babyArrow.x += Note.swagWidth * i;

			var targAlpha = 1;

			if (PlayStateChangeables.middleScroll)
			{
				if (PlayStateChangeables.opponentMode)
				{
					if (player == 1)
					{
						targAlpha = 0;
					}
				}
				else
				{
					if (player == 0)
					{
						targAlpha = 0;
					}
				}
			}

			if (tween)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				createTween(babyArrow, {y: babyArrow.y + 10, alpha: targAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
				babyArrow.alpha = targAlpha;

			babyArrow.ID = i;

			babyArrow.loadLane();
			arrowLanes.add(babyArrow.bgLane);

			switch (player)
			{
				case 0:
					if (!PlayStateChangeables.opponentMode)
					{
						cpuStrums.add(babyArrow);
					}
					else
					{
						playerStrums.add(babyArrow);
					}
				case 1:
					if (!PlayStateChangeables.opponentMode)
					{
						playerStrums.add(babyArrow);
					}
					else
					{
						cpuStrums.add(babyArrow);
					}
			}
			babyArrow.playAnim('static');
			// babyArrow.x += 98.5; // Tryna make it not offset because it was pissing me off + Psych Engine has it somewhat like this.
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
		arrowsGenerated = true;
	}

	private function appearStaticArrows():Void
	{
		var index = 0;
		strumLineNotes.forEach(function(babyArrow:FlxSprite)
		{
			if (isStoryMode && !PlayStateChangeables.middleScroll)
				babyArrow.visible = true;
			if (index > 3 && PlayStateChangeables.middleScroll)
				babyArrow.visible = true;
			index++;
		});
	}

	function tweenCamIn():Void
	{
		createTween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (inst.playing)
				inst.pause();
			if (!SONG.splitVoiceTracks)
			{
				if (vocals != null)
					if (vocals.playing)
						vocals.pause();
			}
			else
			{
				if (vocalsPlayer != null)
					if (vocalsPlayer.playing)
						vocalsPlayer.pause();
				if (vocalsEnemy != null)
					if (vocalsEnemy.playing)
						vocalsEnemy.pause();
			}

			#if FEATURE_DISCORD
			Discord.changePresence("PAUSED on "
				+ SONG.songName
				+ " ("
				+ storyDifficultyText
				+ ") "
				+ Ratings.GenerateLetterRank(accuracy),
				"\nAcc: "
				+ HelperFunctions.truncateFloat(accuracy, 2)
				+ "% | Score: "
				+ songScore
				+ " | Misses: "
				+ misses, iconRPC);
			#end
			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (PauseSubState.goToOptions)
		{
			if (PauseSubState.goBack)
			{
				if (FlxG.save.data.gen)
					Debug.logTrace("Paused.");

				PauseSubState.goToOptions = false;
				PauseSubState.goBack = false;
				openSubState(subStates[0]);
			}
			else
				openSubState(subStates[3]);
		}
		else if (paused)
		{
			if (inst != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;

			if (!PlayStateChangeables.botPlay)
				keyShit();
			paused = false;

			#if FEATURE_DISCORD
			if (startTimer.finished)
			{
				Discord.changePresence(detailsText
					+ " "
					+ SONG.songName
					+ " ("
					+ storyDifficultyText
					+ ") "
					+ Ratings.GenerateLetterRank(accuracy),
					"\nAcc: "
					+ HelperFunctions.truncateFloat(accuracy, 2)
					+ "% | Score: "
					+ songScore
					+ " | Misses: "
					+ misses, iconRPC, true,
					songLength
					- Conductor.songPosition);
			}
			else
			{
				Discord.changePresence(detailsText, SONG.songName + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), iconRPC);
			}
			#end
		}

		super.closeSubState();
	}

	function resyncVocals():Void
	{
		if (endingSong)
			return;
		inst.pause();
		inst.resume();
		inst.time = Conductor.songPosition * songMultiplier;
		if (!SONG.splitVoiceTracks)
		{
			if (!vocals.playing || vocals.time != Conductor.songPosition * songMultiplier)
			{
				vocals.pause();

				if (!(vocals.length < inst.time))
				{
					vocals.play();

					vocals.time = Conductor.songPosition * songMultiplier;
				}
			}
		}
		else
		{
			if (!vocalsPlayer.playing || vocalsPlayer.time != Conductor.songPosition * songMultiplier)
			{
				vocalsPlayer.pause();

				if (!(vocalsPlayer.length < inst.time))
				{
					vocalsPlayer.play();

					vocalsPlayer.time = Conductor.songPosition * songMultiplier;
				}
			}

			if (!vocalsEnemy.playing || vocalsEnemy.time != Conductor.songPosition * songMultiplier)
			{
				vocalsEnemy.pause();

				if (!(vocalsEnemy.length < inst.time))
				{
					vocalsEnemy.play();

					vocalsEnemy.time = Conductor.songPosition * songMultiplier;
				}
			}
		}

		if (inst.playing)
		{
			inst.pitch = songMultiplier;
			if (!SONG.splitVoiceTracks)
			{
				if (vocals.playing)
					vocals.pitch = songMultiplier;
			}
			else
			{
				if (vocalsPlayer.playing && vocalsEnemy.playing)
				{
					vocalsPlayer.pitch = songMultiplier;
					vocalsEnemy.pitch = songMultiplier;
				}
			}
		}

		#if FEATURE_DISCORD
		Discord.changePresence(detailsText
			+ " "
			+ SONG.songName
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"\nAcc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC);
		#end
	}

	public var paused:Bool = false;

	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var nps:Int = 0;
	var maxNPS:Int = 0;

	public var stopUpdate = false;

	public var currentBPM = 0;

	public var updateFrame = 0;

	public var pastScrollChanges:Array<Song.Event> = [];
	public var pastAnimationPlays:Array<Song.Event> = [];
	public var pastZooms:Array<Song.Event> = [];

	var currentLuaIndex = 0;

	override public function update(elapsed:Float)
	{
		if (FlxG.save.data.borderless)
		{
			FlxG.stage.window.borderless = true;
		}
		else
		{
			FlxG.stage.window.borderless = false;
		}

		if (unspawnNotes[0] != null)
		{
			var shit:Float = 2000;
			if (SONG.speed < 1 || scrollSpeed < 1)
				shit /= scrollSpeed == 1 ? SONG.speed : scrollSpeed;
			var time:Float = shit * songMultiplier;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];

				notes.insert(0, dunceNote);

				#if FEATURE_LUAMODCHART
				if (executeModchart)
				{
					new LuaNote(dunceNote, currentLuaIndex);
					dunceNote.luaID = currentLuaIndex;
				}
				#end

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
				currentLuaIndex++;
			}
		}

		// uhhh dont comment out. It breaks everything
		if (!paused)
		{
			tweenManager.update(elapsed);
			timerManager.update(elapsed);
		}

		if (generatedMusic && !paused && songStarted && songMultiplier < 1)
		{
			if (Conductor.songPosition * songMultiplier >= inst.time + 25 || Conductor.songPosition * songMultiplier <= inst.time - 25)
			{
				resyncVocals();
			}
		}

		if (nps >= 0)
			updateScoreText();

		if (inst.playing)
		{
			inst.pitch = songMultiplier;
			if (!SONG.splitVoiceTracks)
			{
				if (vocals.playing)
					vocals.pitch = songMultiplier;
			}
			else
			{
				if (vocalsPlayer.playing && vocalsEnemy.playing)
				{
					vocalsPlayer.pitch = songMultiplier;
					vocalsEnemy.pitch = songMultiplier;
				}
			}
		}

		#if FEATURE_HSCRIPT
		if (scripts != null)
			scripts.executeAllFunc("update", [elapsed]);
		#end

		#if VIDEOS
		if ((cutscene != null && cutscene.isPlaying && inCutscene) && FlxG.keys.justPressed.ANY)
			cutscene.onEndReached.dispatch();
		#end

		if (FlxG.save.data.background)
			Stage.update(elapsed);

		if (generatedMusic)
		{
			if (songStarted && !endingSong)
			{
				if ((inst.length / songMultiplier) - Conductor.songPosition <= 0)
				{
					endingSong = true;
					endSong();
				}
			}
		}

		if (inst.playing)
		{
			var timingSeg = TimingStruct.getTimingAtBeat(curDecimalBeat);

			if (timingSeg != null)
			{
				var timingSegBpm = timingSeg.bpm;

				if (timingSegBpm != Conductor.bpm)
				{
					Debug.logInfo('Timing Struct BPM: ${timingSeg.bpm} | Current Conductor BPM: ${Conductor.bpm}');
					Debug.logInfo("BPM CHANGE to " + timingSegBpm);

					Conductor.changeBPM(timingSegBpm);

					Conductor.crochet = ((60 / (timingSegBpm) * 1000)) / songMultiplier;
					Conductor.stepCrochet = Conductor.crochet / 4;

					Debug.logInfo('Timing Struct BPM: ${timingSeg.bpm} | Current Conductor BPM: ${Conductor.bpm}');

					recalculateAllSectionTimes();
				}
			}
			var newScroll = 1.0;

			for (i in SONG.eventObjects)
			{
				switch (i.type)
				{
					case "Scroll Speed Change":
						if (i.position <= curDecimalBeat && !pastScrollChanges.contains(i))
						{
							pastScrollChanges.push(i);
							newScroll = i.value;
							Debug.logTrace("SCROLL SPEED CHANGE to " + newScroll + " WITH A TIME OF " + i.value2);

							if (newScroll != 0)
								changeScrollSpeed(newScroll, i.value2, FlxEase.linear);
						}
						speedChanged = true;
					case "Play Animation":
						if (i.position <= curDecimalBeat && !pastAnimationPlays.contains(i))
						{
							pastAnimationPlays.push(i);
							var char:Character = dad;
							switch (i.value.toLowerCase())
							{
								case 'dad' | 'opponent':
									char = dad;
								case 'bf' | 'boyfriend' | 'player':
									char = boyfriend;
								case 'gf' | 'girlfriend':
									if (gf != null) char = gf;
								default:
									char = dad;
							}

							if (char != null)
							{
								char.playAnim(i.value2, true);
							}
						}
					case "Change Camera Zoom":
						if (i.position <= curDecimalBeat && !pastZooms.contains(i))
						{
							pastZooms.push(i);
							var camToZoom = camGame;
							switch (i.value.toLowerCase())
							{
								case 'hud' | 'camhud':
									zoomForHUDTweens += i.value2;
								case 'game' | 'main' | 'camgame':
									zoomForTweens += i.value2;
								default:
									zoomForTweens += i.value2;
							}
						}
				}
			}
		}

		if (PlayStateChangeables.botPlay && FlxG.keys.justPressed.F1)
			camHUD.visible = !camHUD.visible;

		#if FEATURE_LUAMODCHART
		if (executeModchart && luaModchart != null)
		{
			luaModchart.setVar('songPos', Conductor.songPosition);
			luaModchart.setVar('hudZoom', camHUD.zoom);
			luaModchart.setVar('curBeat', HelperFunctions.truncateFloat(curDecimalBeat, 3));
			luaModchart.setVar('cameraZoom', FlxG.camera.zoom);
			luaModchart.executeState('onUpdate', [elapsed]);

			for (key => value in luaModchart.luaWiggles)
			{
				value.update(elapsed);
			}

			PlayStateChangeables.useDownscroll = luaModchart.getVar("downscroll", "bool");

			PlayStateChangeables.middleScroll = luaModchart.getVar("middleScroll", "bool");

			/*for (i in 0...strumLineNotes.length) {
				var member = strumLineNotes.members[i];
				member.x = luaModchart.getVar("strum" + i + "X", "float");
				member.y = luaModchart.getVar("strum" + i + "Y", "float");
				member.angle = luaModchart.getVar("strum" + i + "Angle", "float");
			}*/

			FlxG.camera.angle = luaModchart.getVar('cameraAngle', 'float');
			camHUD.angle = luaModchart.getVar('camHudAngle', 'float');

			var p1 = luaModchart.getVar("strumLine1Visible", 'bool');
			var p2 = luaModchart.getVar("strumLine2Visible", 'bool');

			for (i in 0...4)
			{
				strumLineNotes.members[i].visible = p1;
				if (i <= playerStrums.length)
					playerStrums.members[i].visible = p2;
			}
		}
		#end

		// reverse iterate to remove oldest notes first and not invalidate the iteration
		// stop iteration as soon as a note is not removed
		// all notes should be kept in the correct order and this is optimal, safe to do every frame/update
		if (notesHitArray.length > 0)
		{
			var data = Date.now().getTime();
			var balls = notesHitArray.length - 1;
			while (balls >= 0)
			{
				var cock:Float = notesHitArray[balls];

				if (cock + 1000 < data)
					notesHitArray.remove(cock);
				else
					break;
				balls--;
			}
			nps = notesHitArray.length;
			if (nps > maxNPS)
				maxNPS = nps;
		}

		if (FlxG.keys.justPressed.NINE)
			iconP1.swapOldIcon();

		if (#if android FlxG.android.justReleased.BACK && !inCutscene || #end controls.PAUSE && startedCountdown && canPause && !cannotDie)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// 1 / 1000000 chance for Gitaroo Man easter egg
			// happened to me way to frequently. Annoying
			if (FlxG.random.bool(0.0001))
			{
				FlxG.switchState(new GitarooPause());
			}
			else
				openSubState(subStates[0]);
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			wentToChartEditor = true;
			if (PlayStateChangeables.mirrorMode)
				PlayStateChangeables.mirrorMode = !PlayStateChangeables.mirrorMode;
			executeModchart = false;
			cannotDie = true;
			persistentUpdate = false;
			ChartingState.clean = true;
			LoadingState.loadAndSwitchState(new ChartingState());
		}

		if (FlxG.keys.justPressed.EIGHT && FlxG.save.data.background)
		{
			paused = true;
			new FlxTimer().start(0.3, function(tmr:FlxTimer)
			{
				for (bg in Stage.toAdd)
				{
					remove(bg);
				}
				for (array in Stage.layInFront)
				{
					for (bg in array)
						remove(bg);
				}
				for (group in Stage.swagGroup)
				{
					remove(group);
				}
				remove(boyfriend);
				remove(dad);
				if (gf != null)
					remove(gf);
			});
			StageDebugState.Stage = Stage;
			StageDebugState.fromEditor = false;
			LoadingState.loadAndSwitchState(new StageDebugState(Stage.curStage, if (gf != null) gf.curCharacter else "gf", boyfriend.curCharacter,
				dad.curCharacter));
			#if FEATURE_LUAMODCHART
			if (luaModchart != null)
			{
				luaModchart.die();
				luaModchart = null;
			}
			#end
		}

		if (FlxG.keys.justPressed.TWO && songStarted)
		{
			if (!usedTimeTravel && Conductor.songPosition + 10000 < inst.length)
			{
				usedTimeTravel = true;
				inst.pause();
				if (!SONG.splitVoiceTracks)
					vocals.pause();
				else
				{
					vocalsPlayer.pause();
					vocalsEnemy.pause();
				}
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.strumTime - 500 < Conductor.songPosition)
					{
						daNote.active = false;
						daNote.visible = false;

						destroyNote(daNote);
					}
				});

				inst.time = Conductor.songPosition;
				inst.resume();
				if (!SONG.splitVoiceTracks)
				{
					vocals.time = Conductor.songPosition;
					vocals.resume();
				}
				else
				{
					vocalsPlayer.time = Conductor.songPosition;
					vocalsPlayer.resume();
					vocalsEnemy.time = Conductor.songPosition;
					vocalsEnemy.resume();
				}
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
				{
					usedTimeTravel = false;
				});
			}
		}

		if (skipActive && Conductor.songPosition >= skipTo)
		{
			remove(skipText);
			skipActive = false;
		}

		if (FlxG.keys.justPressed.SPACE && skipActive)
		{
			inst.pause();
			if (!SONG.splitVoiceTracks)
				vocals.pause();
			else
			{
				vocalsPlayer.pause();
				vocalsEnemy.pause();
			}
			Conductor.songPosition = skipTo;
			Conductor.rawPosition = skipTo;
			inst.time = Conductor.songPosition;
			inst.resume();
			if (!SONG.splitVoiceTracks)
			{
				vocals.time = Conductor.songPosition;
				vocals.resume();
			}
			else
			{
				vocalsPlayer.time = Conductor.songPosition;
				vocalsPlayer.resume();
				vocalsEnemy.time = Conductor.songPosition;
				vocalsEnemy.resume();
			}
			createTween(skipText, {alpha: 0}, 0.2, {
				onComplete: function(tw)
				{
					remove(skipText);
				}
			});
			skipActive = false;
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				Conductor.rawPosition = Conductor.songPosition;
				if (Conductor.songPosition >= 0)
				{
					startSong();
				}
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;
			Conductor.rawPosition = inst.time;

			songPositionBar = (Conductor.songPosition - songLength) / 1000;
			// currentSection = getSectionByTime(Conductor.songPosition / songMultiplier);
			if (!paused)
			{
				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
				var curTime:Float = inst.time / songMultiplier;

				if (curTime < 0)
					curTime = 0;
				var secondsTotal:Int = Math.floor(((curTime - songLength) / 1000));

				if (secondsTotal < 0)
					secondsTotal = 0;
				songName.text = SONG.songName + ' (' + FlxStringUtil.formatTime((songLength - secondsTotal), false) + ')';
			}
		}

		if (generatedMusic && currentSection != null)
		{
			if (allowedToCheer)
			{
				if (gf.animation.curAnim.name == 'danceLeft'
					|| gf.animation.curAnim.name == 'danceRight'
					|| gf.animation.curAnim.name == 'idle'
					&& gf != null)
				{
					switch (curSong)
					{
						case 'Philly Nice':
							{
								if (curBeat < 250)
								{
									if (curBeat != 184 && curBeat != 216)
									{
										if (curBeat % 16 == 8)
										{
											if (!triggeredAlready)
											{
												gf.playAnim('cheer');
												triggeredAlready = true;
											}
										}
										else
											triggeredAlready = false;
									}
								}
							}
						case 'Bopeebo':
							{
								if (curBeat > 5 && curBeat < 130)
								{
									if (curBeat % 8 == 7)
									{
										if (!triggeredAlready)
										{
											gf.playAnim('cheer', true);
											triggeredAlready = true;
										}
									}
									else
										triggeredAlready = false;
								}
							}
						case 'Blammed':
							{
								if (curBeat > 30 && curBeat < 190)
								{
									if (curBeat < 90 || curBeat > 128)
									{
										if (curBeat % 4 == 2)
										{
											if (!triggeredAlready)
											{
												gf.playAnim('cheer', true);
												triggeredAlready = true;
											}
										}
										else
											triggeredAlready = false;
									}
								}
							}
						case 'Cocoa':
							{
								if (curBeat < 170)
								{
									if (curBeat < 65 || curBeat > 130 && curBeat < 145)
									{
										if (curBeat % 16 == 15)
										{
											if (!triggeredAlready)
											{
												gf.playAnim('cheer', true);
												triggeredAlready = true;
											}
										}
										else
											triggeredAlready = false;
									}
								}
							}
						case 'Eggnog':
							{
								if (curBeat > 10 && curBeat != 111 && curBeat < 220)
								{
									if (curBeat % 8 == 7)
									{
										if (!triggeredAlready)
										{
											gf.playAnim('cheer', true);
											triggeredAlready = true;
										}
									}
									else
										triggeredAlready = false;
								}
							}
					}
				}
			}
		}

		if (health <= 0)
			health = 0;
		else if (health >= 2)
			health = 2;

		FlxG.watch.addQuick("curBPM", Conductor.bpm);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("stepShit", curStep);

		if (health <= 0 && !cannotDie && !PlayStateChangeables.practiceMode)
		{
			if (!usedTimeTravel)
			{
				persistentUpdate = false;
				persistentDraw = false;
				paused = true;
				if (!SONG.splitVoiceTracks)
					vocals.stop();
				else
				{
					vocalsPlayer.stop();
					vocalsEnemy.stop();
				}
				inst.stop();
				if (FlxG.save.data.InstantRespawn || (PlayStateChangeables.opponentMode && !dad.animOffsets.exists('firstDeath')))
				{
					LoadingState.loadAndSwitchState(new PlayState());
				}
				else
				{
					openSubState(subStates[2]);
				}

				isDead = true;

				#if FEATURE_DISCORD
				// Game Over doesn't get his own variable because it's only used here
				Discord.changePresence("GAME OVER -- "
					+ SONG.songName
					+ " ("
					+ storyDifficultyText
					+ ") "
					+ Ratings.GenerateLetterRank(accuracy),
					"\nAcc: "
					+ HelperFunctions.truncateFloat(accuracy, 2)
					+ "% | Score: "
					+ songScore
					+ " | Misses: "
					+ misses, iconRPC);
				#end
			}
			else
				health = 1;
		}
		if (!inCutscene && FlxG.save.data.resetButton)
		{
			var resetBind = FlxKey.fromString(FlxG.save.data.resetBind);

			if ((FlxG.keys.anyJustPressed([resetBind])))
			{
				persistentUpdate = false;
				persistentDraw = false;
				paused = true;
				if (!SONG.splitVoiceTracks)
					vocals.stop();
				else
				{
					vocalsPlayer.stop();
					vocalsEnemy.stop();
				}
				inst.stop();
				if (FlxG.save.data.InstantRespawn || (PlayStateChangeables.opponentMode && !dad.animOffsets.exists('firstDeath')))
				{
					LoadingState.loadAndSwitchState(new PlayState());
				}
				else
				{
					openSubState(subStates[2]);
				}

				isDead = true;

				#if FEATURE_DISCORD
				Discord.changePresence("GAME OVER -- "
					+ SONG.songName
					+ " ("
					+ storyDifficultyText
					+ ") "
					+ Ratings.GenerateLetterRank(accuracy),
					"\nAcc: "
					+ HelperFunctions.truncateFloat(accuracy, 2)
					+ "% | Score: "
					+ songScore
					+ " | Misses: "
					+ misses, iconRPC);
				#end
			}
		}

		super.update(elapsed);

		if (songStarted)
		{
			var bpmRatio = Conductor.bpm / 100;

			if (PlayStateChangeables.zoom < 0.8)
				PlayStateChangeables.zoom = 0.8;
			if (PlayStateChangeables.zoom > 1.2)
				PlayStateChangeables.zoom = 1.2;
			// this motherfucker fucks me so much.

			FlxG.camera.zoom = FlxMath.lerp(zoomForTweens, FlxG.camera.zoom,
				CoolUtil.boundTo(1 - (elapsed * 3.125 * bpmRatio * songMultiplier * zoomMultiplier), 0, 1));
			camHUD.zoom = FlxMath.lerp(PlayStateChangeables.zoom * zoomForHUDTweens, camHUD.zoom,
				CoolUtil.boundTo(1 - (elapsed * 3.125 * bpmRatio * songMultiplier * zoomMultiplier), 0, 1));
			camStrums.zoom = camHUD.zoom;
		}

		if (generatedMusic && !(inCutscene || inCinematic))
		{
			var holdArray:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
			var leSpeed = scrollSpeed == 1 ? SONG.speed : scrollSpeed;
			var stepHeight = (0.45 * fakeNoteStepCrochet * FlxMath.roundDecimal((SONG.speed * Math.pow(PlayState.songMultiplier, 2)), 2));

			// hell
			// note scroll code (mostly)

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.noteData == -1)
				{
					Debug.logWarn('Weird Note detected! Note Data = "${daNote.rawNoteData}" is not valid, deleting...');
					destroyNote(daNote);
				}

				if (!daNote.active)
				{
					destroyNote(daNote);
					return;
				}

				var strum:FlxTypedGroup<StaticArrow> = playerStrums;
				if (!daNote.mustPress)
					strum = cpuStrums;

				#if FEATURE_HSCRIPT
				if (!ScriptUtil.hasPause(scripts.executeAllFunc("notesUpdate", [daNote])))
				{
					scripts.executeAllFunc("notesUpdate", [daNote]);
				};
				#end

				var strumY = strum.members[daNote.noteData].y;

				var strumX = strum.members[daNote.noteData].x;

				var strumAngle = strum.members[daNote.noteData].modAngle;

				var strumScrollType = strum.members[daNote.noteData].downScroll;

				var strumDirection = strum.members[daNote.noteData].direction;

				var angleDir = strumDirection * Math.PI / 180;

				var origin = strumY + Note.swagWidth / 2;

				if (daNote.isSustainNote)
					daNote.x = (strumX + Math.cos(angleDir) * daNote.distance) + (Note.swagWidth / 3);
				else
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

				if (SONG.style.toLowerCase() == 'pixel' && daNote.isSustainNote)
					daNote.x -= 5;

				daNote.y = strumY + Math.sin(angleDir) * daNote.distance;
				if (!daNote.overrideDistance)
				{
					if (PlayStateChangeables.useDownscroll)
					{
						daNote.distance = (0.45 * ((Conductor.songPosition - daNote.strumTime)) * (FlxMath.roundDecimal(leSpeed, 2)) * daNote.speedMultiplier)
							- daNote.noteYOff;
					}
					else
						daNote.distance = (-0.45 * ((Conductor.songPosition - daNote.strumTime)) * (FlxMath.roundDecimal(leSpeed, 2)) * daNote.speedMultiplier)
							+ daNote.noteYOff;
				}

				var swagRect:FlxRect = daNote.clipRect;
				if (swagRect == null)
					swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);

				if (daNote.isSustainNote && daNote.prevNote.wasGoodHit)
				{
					if (strumScrollType)
					{
						// daNote.y = (strumY + Math.sin(angleDir) * daNote.distance) - (daNote.height - Note.swagWidth);

						if (daNote.sustainActive)
						{
							if ((daNote.causesMisses) && daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= origin)
							{
								// Clip to strumline
								swagRect.width = daNote.frameWidth;
								swagRect.height = (origin - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;
								daNote.clipRect = swagRect;
							}
						}
					}
					else
					{
						if (daNote.sustainActive)
						{
							// Clip to strumline
							if ((daNote.causesMisses) && daNote.y + daNote.offset.y * daNote.scale.y <= origin)
							{
								swagRect.y = (origin - daNote.y) / daNote.scale.y;
								swagRect.width = daNote.width / daNote.scale.x;
								swagRect.height = (daNote.height / daNote.scale.y) - swagRect.y;
								daNote.clipRect = swagRect;
							}
						}
					}
				}

				if (!daNote.modifiedByLua)
				{
					daNote.visible = strum.members[Math.floor(Math.abs(daNote.noteData))].visible;
					if (!daNote.isSustainNote)
					{
						daNote.alpha = strum.members[Math.floor(Math.abs(daNote.noteData))].alpha;
						daNote.modAngle = strum.members[Math.floor(Math.abs(daNote.noteData))].modAngle;
					}
					if (daNote.isSustainNote && daNote.sustainActive)
					{
						daNote.modAlpha = strum.members[Math.floor(Math.abs(daNote.noteData))].alpha;
					}
				}

				if (!daNote.mustPress)
				{
					if (Conductor.songPosition >= daNote.strumTime && daNote.botplayHit)
						opponentNoteHit(daNote);
				}
				else
				{
					if (PlayStateChangeables.botPlay)
						handleBotplay(daNote);
					else if (!PlayStateChangeables.botPlay && daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && keys[daNote.noteData]
						&& daNote.sustainActive)
						handleHolds(daNote);
				}

				// there was some code idk what it did but it fucked with color quantization shit. ik its a feature not many like but I like it.

				if (!daNote.mustPress && PlayStateChangeables.middleScroll && !executeModchart)
					daNote.visible = false;

				if (daNote.exists)
				{
					if (Conductor.songPosition > Ratings.timingWindows[0].timingWindow + daNote.strumTime)
					{
						if (daNote.isSustainNote && daNote.wasGoodHit && Conductor.songPosition >= daNote.strumTime)
						{
							destroyNote(daNote);
						}
						if (daNote != null)
						{
							if (daNote.mustPress && daNote.tooLate && !daNote.canBeHit && daNote.mustPress)
							{
								if (daNote.isSustainNote && daNote.wasGoodHit && daNote.causesMisses)
								{
									destroyNote(daNote);
								}
								else
								{
									switch (daNote.noteShit.toLowerCase())
									{
										case 'hurt':
										default:
											if (daNote.isSustainNote)
											{
												// totalNotesHit += 1;
											}
											else
											{
												if (daNote.isParent && daNote.visible)
												{
													// health -= 0.15; // give a health punishment for failing a LN
													Debug.logTrace("User failed Sustain note at the start of sustain.");
													for (i in daNote.children)
													{
														i.sustainActive = false;
														health -= (daNote.missHealth * PlayStateChangeables.healthLoss) / daNote.children.length;
													}
													noteMiss(daNote.noteData, daNote);
												}
												else
												{
													if (!daNote.wasGoodHit && !daNote.isSustainNote && daNote.causesMisses)
													{
														health -= (daNote.missHealth * PlayStateChangeables.healthLoss);
														Debug.logTrace("User failed note.");
														noteMiss(daNote.noteData, daNote);
													}
												}
											}
									}
									destroyNote(daNote);
								}
							}
						}
					}

					if (!PlayStateChangeables.botPlay)
						if (daNote != null)
							if (daNote.mustPress)
							{
								if (!daNote.wasGoodHit
									&& daNote.isSustainNote
									&& daNote.sustainActive
									&& !daNote.isSustainEnd
									&& daNote.causesMisses
									&& !holdArray[Std.int(Math.abs(daNote.noteData))])
								{
									// there should be a ! infront of the wasGoodHit one but it'd cause a miss per every sustain note.
									// now it just misses on the slightest sustain end for some reason.
									// nvm I fixed it a long time ago
									Debug.logTrace("User released key while playing a sustain at: " + daNote.spotInLine);
									for (i in daNote.parent.children)
									{
										i.sustainActive = false;
										health -= (daNote.missHealth * PlayStateChangeables.healthLoss) / daNote.parent.children.length;
									}
									noteMiss(daNote.noteData, daNote);
								}
							}
				}
			});
		}

		charactersDance();

		if (FlxG.keys.justPressed.ONE)
			endSong();
		for (i in shaderUpdates)
			i(elapsed);

		if (FlxG.save.data.smoothHealthbar)
			shownHealth = FlxMath.lerp(shownHealth, health, CoolUtil.boundTo(elapsed * 15 * songMultiplier, 0, 1));
		else
			shownHealth = health;

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, FlxMath.bound(1 - (elapsed * 9 * songMultiplier), 0, 1));
		if (!FlxG.save.data.motion)
			iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, FlxMath.bound(1 - (elapsed * 9 * songMultiplier), 0, 1));
		if (!FlxG.save.data.motion)
			iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(PlayStateChangeables.opponentMode ? 100 - healthBar.percent : healthBar.percent, 0, 100, 100, 0) * 0.01)
				- iconOffset);
		iconP2.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(PlayStateChangeables.opponentMode ? 100 - healthBar.percent : healthBar.percent, 0, 100, 100, 0) * 0.01))
			- (iconP2.width - iconOffset);
		try
		{
			if (iconP1.isAnimated)
			{
				if (!PlayStateChangeables.opponentMode)
				{
					if (healthBar.percent < 20 && icon1AnimArray[1])
					{
						animName = 'Lose';
					}
					else
					{
						animName = 'Idle';
					}

					if (iconP1.animation.curAnim.finished || (animName != iconP1.animation.curAnim.name))
					{
						iconP1.playAnim(animName, true);
					}
				}
				else
				{
					if (healthBar.percent > 80 && icon1AnimArray[0])
					{
						animName = 'Lose';
					}
					else
					{
						animName = 'Idle';
					}

					if (iconP1.animation.curAnim.finished || (animName != iconP1.animation.curAnim.name))
					{
						iconP1.playAnim(animName, true);
					}
				}
			}
			else
			{
				if (!PlayStateChangeables.opponentMode)
				{
					if (healthBar.percent < 20)
						iconP1.animation.curAnim.curFrame = 1;
					else if (healthBar.percent > 80 && iconP1.hasWinningIcon)
						iconP1.animation.curAnim.curFrame = 2;
					else
						iconP1.animation.curAnim.curFrame = 0;
				}
				else
				{
					if (healthBar.percent > 80)
						iconP1.animation.curAnim.curFrame = 1;
					else if (healthBar.percent < 20 && iconP1.hasWinningIcon)
						iconP1.animation.curAnim.curFrame = 2;
					else
						iconP1.animation.curAnim.curFrame = 0;
				}
			}

			if (iconP2.isAnimated)
			{
				if (!PlayStateChangeables.opponentMode)
				{
					if (healthBar.percent > 80 && icon2AnimArray[0])
					{
						animName = 'Lose';
					}
					else
					{
						animName = 'Idle';
					}

					if (iconP2.animation.curAnim.finished || (animName != iconP2.animation.curAnim.name))
					{
						iconP2.playAnim(animName, true);
					}
				}
				else
				{
					if (healthBar.percent < 20 && icon2AnimArray[0])
					{
						animName = 'Lose';
					}
					else
					{
						animName = 'Idle';
					}

					if (iconP2.animation.curAnim.finished || (animName != iconP2.animation.curAnim.name))
					{
						iconP2.playAnim(animName, true);
					}
				}
			}
			else
			{
				if (PlayStateChangeables.opponentMode)
				{
					if (healthBar.percent < 20)
						iconP2.animation.curAnim.curFrame = 1;
					else if (healthBar.percent > 80 && iconP2.hasWinningIcon)
						iconP2.animation.curAnim.curFrame = 2;
					else
						iconP2.animation.curAnim.curFrame = 0;
				}
				else
				{
					if (healthBar.percent > 80)
						iconP2.animation.curAnim.curFrame = 1;
					else if (healthBar.percent < 20 && iconP2.hasWinningIcon)
						iconP2.animation.curAnim.curFrame = 2;
					else
						iconP2.animation.curAnim.curFrame = 0;
				}
			}

			// Debug.logTrace(healthBar.percent);
		}
		catch (e)
		{
			Debug.logTrace(e);
		}

		// I don't wanna talk about the code above.

		#if FEATURE_LUAMODCHART
		if (executeModchart && luaModchart != null)
		{
			luaModchart.executeState('onUpdatePost', [elapsed]);
		}
		#end
		#if FEATURE_HSCRIPT
		if (scripts != null)
			scripts.executeAllFunc("updatePost", [elapsed]);
		#end
	}

	function endSong():Void
	{
		camZooming = mobileControls.visible = false;
		endingSong = true;
		inDaPlay = false;
		Lib.current.stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleInput);
		Lib.current.stage.removeEventListener(KeyboardEvent.KEY_UP, releaseInput);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		#if FEATURE_LUAMODCHART
		if (luaModchart != null)
		{
			luaModchart.die();
			luaModchart = null;
		}
		#end
		poggers(true);

		canPause = false;
		inst.volume = 0;
		if (!SONG.splitVoiceTracks)
		{
			vocals.volume = 0;
			vocals.stop();
		}
		else
		{
			vocalsPlayer.volume = 0;
			vocalsPlayer.stop();
			vocalsEnemy.volume = 0;
			vocalsEnemy.stop();
		}
		inst.stop();

		var legitTimings:Bool = true;
		for (rating in Ratings.timingWindows)
		{
			if (rating.timingWindow != rating.defaultTimingWindow)
			{
				legitTimings = false;
				break;
			}
		}

		var superMegaConditionShit:Bool = legitTimings
			&& !PlayState.usedBot
			&& !FlxG.save.data.practice
			&& PlayStateChangeables.holds
			&& !PlayState.wentToChartEditor
			&& HelperFunctions.truncateFloat(PlayStateChangeables.healthGain, 2) <= 1
			&& HelperFunctions.truncateFloat(PlayStateChangeables.healthLoss, 2) >= 1;

		if (SONG.validScore && superMegaConditionShit)
		{
			Highscore.saveScore(PlayState.SONG.songId, Math.round(songScore), storyDifficulty, songMultiplier);
			Highscore.saveCombo(PlayState.SONG.songId, Ratings.GenerateComboRank(accuracy), storyDifficulty, songMultiplier);
			Highscore.saveAcc(PlayState.SONG.songId, HelperFunctions.truncateFloat(accuracy, 2), storyDifficulty, songMultiplier);
			Highscore.saveLetter(PlayState.SONG.songId, Ratings.GenerateLetterRank(accuracy), storyDifficulty, songMultiplier);
		}

		storyPlaylist.remove(storyPlaylist[0]);

		#if FEATURE_HSCRIPT
		if (ScriptUtil.hasPause(scripts.executeAllFunc("endSong")))
			return;
		#end

		if (!isStoryMode || storyPlaylist.length <= 0)
		{
			if (FlxG.save.data.songPosition)
			{
				createTween(songName, {alpha: 0}, 1, {ease: FlxEase.circIn});
				createTween(songPosBar, {alpha: 0}, 1, {ease: FlxEase.circIn});
				createTween(bar, {alpha: 0}, 1, {ease: FlxEase.circIn});
			}
			createTween(judgementCounter, {alpha: 0}, 1, {ease: FlxEase.circIn});
			createTween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.circIn});
			createTween(healthBar, {alpha: 0}, 1, {ease: FlxEase.circIn});
			createTween(healthBarBG, {alpha: 0}, 1, {ease: FlxEase.circIn});
			createTween(iconP1, {alpha: 0}, 1, {ease: FlxEase.circIn});
			createTween(iconP2, {alpha: 0}, 1, {ease: FlxEase.circIn});
			for (note in 0...strumLineNotes.length)
				createTween(strumLineNotes.members[note], {y: strumLineNotes.members[note].y - 10, alpha: 0}, 0.4, {
					ease: FlxEase.circOut,
					startDelay: 0.2 + (0.2 * note),
					onComplete: function(t)
					{
						if (note == 7)
						{
							Debug.logTrace("we're fuckin ending the song ");
							songEnd();
						}
					}
				});
		}
		else
			songEnd();
	}

	inline function songEnd()
	{
		if (isStoryMode)
		{
			campaignAccuracy += HelperFunctions.truncateFloat(accuracy, 2) / initStoryLength;
			campaignScore += Math.round(songScore);
			campaignMarvs += marvs;
			campaignMisses += misses;
			campaignSicks += sicks;
			campaignGoods += goods;
			campaignBads += bads;
			campaignShits += shits;

			if (storyPlaylist.length <= 0)
			{
				paused = true;
				inst.stop();

				if (!SONG.splitVoiceTracks)
					vocals.stop();
				else
				{
					vocalsPlayer.stop();
					vocalsEnemy.stop();
				}

				#if FEATURE_LUAMODCHART
				if (luaModchart != null)
				{
					luaModchart.die();
					luaModchart = null;
				}
				#end

				if (SONG.validScore)
				{
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty, 1);
				}

				if (FlxG.save.data.scoreScreen)
				{
					persistentUpdate = false;
					inResults = true;
					openSubState(subStates[1]);
				}
				else
				{
					GameplayCustomizeState.freeplayNoteStyle = 'default';
					GameplayCustomizeState.freeplayWeek = 1;
					FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "freakyMenu" : "ke_freakyMenu"));
					MainMenuState.freakyPlaying = true;
					Conductor.changeBPM(102);
					MusicBeatState.switchState(new StoryMenuState());
				}
			}
			else
			{
				var diff:String = CoolUtil.getSuffixFromDiff(CoolUtil.difficultyArray[storyDifficulty]);

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				if (FlxTransitionableState.skipNextTransIn)
				{
					CustomFadeTransition.nextCamera = null;
				}

				Debug.logInfo('Loading Next Story Song ${PlayState.storyPlaylist[0]}${diff}');

				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0], diff);
				inst.stop();

				LoadingState.loadAndSwitchState(new PlayState());
			}
		}
		else
		{
			paused = true;
			inst.stop();
			if (!SONG.splitVoiceTracks)
				vocals.stop();
			else
			{
				vocalsPlayer.stop();
				vocalsEnemy.stop();
			}
			if (FlxG.save.data.scoreScreen)
			{
				persistentUpdate = false;
				inResults = true;
				openSubState(subStates[1]);
			}
			else
			{
				LoadingState.loadAndSwitchState(new FreeplayState());
			}
		}
	}

	function percentageOfSong():Float
	{
		return (Conductor.songPosition / songLength) * 100;
	}

	public var endingSong:Bool = false;

	var hits:Array<Float> = [];
	var offsetTest:Float = 0;

	public var currentShaders:Array<FlxRuntimeShader> = [];

	private function setShaders(obj:Dynamic, shaders:Array<RuntimeShader>)
	{
		#if (!flash && sys)
		var filters = [];

		for (shader in shaders)
		{
			filters.push(new ShaderFilter(shader));

			if (!Std.isOfType(obj, FlxCamera))
			{
				obj.shader = shader;

				return true;
			}

			currentShaders.push(shader);
		}
		if (Std.isOfType(obj, FlxCamera))
			obj.setFilters(filters);

		return true;
		#end
	}

	private function removeShaders(obj:Dynamic)
	{
		#if (!flash && sys)
		var filters = [];

		for (shader in currentShaders)
		{
			currentShaders.remove(shader);
		}

		if (!Std.isOfType(obj, FlxCamera))
		{
			obj.shader = null;

			return true;
		}

		if (Std.isOfType(obj, FlxCamera))
			obj.setFilters(filters);

		return true;
		#end
	}

	public function getRatesScore(rate:Float, score:Float):Float
	{
		var rateX:Float = 1;
		var lastScore:Float = score;
		var pr = rate - 0.05;
		if (pr < 1.00)
			pr = 1;

		while (rateX <= pr)
		{
			if (rateX > pr)
				break;
			lastScore = score + ((lastScore * rateX) * 0.022);
			rateX += 0.05;
		}

		var actualScore = Math.round(score + (Math.floor((lastScore * pr)) * 0.022));

		return actualScore;
	}

	var timeShown = 0;
	var currentTimingShown:FlxText = new FlxText(0, 0, 0, "0ms");
	var rating:FlxSprite = new FlxSprite();

	var lastRating:String = '';

	private function popUpScore(daNote:Note):Void
	{
		var noteDiff:Float = (daNote.strumTime - Conductor.songPosition);
		var styleShit:String = (STYLE.style == null ? 'default' : STYLE.style).toLowerCase();
		var noteDiffAbs = Math.abs(noteDiff);
		if (!PlayStateChangeables.botPlay)
		{
			if (FlxG.save.data.showMs)
			{
				currentTimingShown.alpha = 1;
				tweenManager.cancelTweensOf(currentTimingShown);
				currentTimingShown.alpha = 1;
			}

			rating.velocity.y = 0;
			rating.velocity.x = 0;
			tweenManager.cancelTweensOf(rating);
			rating.alpha = 1;
		}

		if (PlayStateChangeables.botPlay)
			noteDiff = 0;

		var daRating:RatingWindow = Ratings.judgeNote(noteDiff);

		var wife:Float = 0;
		if (!daNote.isSustainNote)
			wife = EtternaFunctions.wife3(noteDiffAbs);

		if (!SONG.splitVoiceTracks)
			vocals.volume = 1;
		else
			vocalsPlayer.volume = 1;

		var score:Float = 0;

		if (FlxG.save.data.accuracyMod == 1)
			totalNotesHit += wife;
		else
			totalNotesHit += daRating.accuracyBonus;

		totalPlayed += 1;

		daNote.rating = daRating;

		switch (daRating.name.toLowerCase())
		{
			case 'shit':
				shits += 1;
			case 'bad':
				bads += 1;
			case 'good':
				goods += 1;
			case 'sick':
				sicks += 1;
			case 'marv':
				marvs += 1;
		}

		if (!daNote.isSustainNote)
		{
			ResultsScreen.instance.registerHit(daNote);
		}

		if (daRating.causeMiss)
		{
			misses++;
			combo = 0;
		}

		score = daRating.scoreBonus;
		var result = 0.06;
		switch (daNote.noteShit.toLowerCase())
		{
			case 'must press':
				result = 0.8;
			default:
				result = daRating.healthBonus > 0 ? daRating.healthBonus * PlayStateChangeables.healthGain : daRating.healthBonus * PlayStateChangeables.healthLoss;
		}

		health += result;

		daRating.count++;

		if ((daRating.doNoteSplash && daNote.canNoteSplash) && FlxG.save.data.notesplashes)
		{
			spawnNoteSplashOnNote(daNote);
		}

		if (FlxG.save.data.scoreMod == 1)
			score = EtternaFunctions.getMSScore(noteDiffAbs);
		else if (songMultiplier >= 1.05)
			score = getRatesScore(songMultiplier, score);

		songScore += Math.round(score);

		if (lastRating != daRating.name.toLowerCase())
		{
			rating.loadGraphic(Paths.image('hud/$styleShit/' + daRating.name.toLowerCase()));
			rating.setGraphicSize(Std.int(rating.width * STYLE.scale * 0.7));

			if (STYLE.antialiasing == false)
				rating.antialiasing = false;
		}

		lastRating = daRating.name.toLowerCase();
		rating.updateHitbox();

		rating.x = FlxG.save.data.changedHitX;
		rating.y = FlxG.save.data.changedHitY;

		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.moves = true;
		rating.acceleration.y = 550;

		if (FlxG.save.data.showMs)
		{
			msTiming = HelperFunctions.truncateFloat(noteDiff, 2);
			if (PlayStateChangeables.botPlay)
				msTiming = 0;
		}

		timeShown = 0;

		currentTimingShown.color = daRating.displayColor;
		currentTimingShown.font = Paths.font('vcr.ttf');
		currentTimingShown.borderStyle = OUTLINE_FAST;
		currentTimingShown.borderSize = 1;
		currentTimingShown.borderColor = FlxColor.BLACK;
		currentTimingShown.text = msTiming + "ms";
		currentTimingShown.size = 20;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('hud/$styleShit/combo'));
		comboSpr.screenCenter();
		currentTimingShown.x = rating.x + 150;
		currentTimingShown.y = rating.y + 85;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.moves = true;

		currentTimingShown.screenCenter();
		currentTimingShown.x = rating.x + 100;
		currentTimingShown.alignment = FlxTextAlign.RIGHT;
		currentTimingShown.y = rating.y + 100;

		if (STYLE.style == 'Pixel')
		{
			currentTimingShown.x -= 15;
			currentTimingShown.y -= 15;
			comboSpr.x += 5.5;
			comboSpr.y += 29.5;
		}

		comboSpr.velocity.x += FlxG.random.int(1, 10);

		currentTimingShown.updateHitbox();
		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		var comboSplit:Array<String> = (combo + "").split('');

		if (combo > highestCombo)
			highestCombo = combo - 1;

		// make sure we have 3 digits to display (looks weird otherwise lol)
		if (comboSplit.length == 1)
		{
			seperatedScore.push(0);
			seperatedScore.push(0);
		}
		else if (comboSplit.length == 2)
			seperatedScore.push(0);

		for (i in 0...comboSplit.length)
		{
			var str:String = comboSplit[i];
			seperatedScore.push(Std.parseInt(str));
		}

		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				if (lastScore[0] != null)
					lastScore[0].destroy();
				lastScore.remove(lastScore[0]);
			}
		}

		var daLoop:Int = 0;
		if (FlxG.save.data.showNum)
		{
			for (i in seperatedScore)
			{
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('hud/$styleShit/' + 'num' + Std.int(i)));
				numScore.setGraphicSize(Std.int(numScore.width * STYLE.scale));
				numScore.cameras = [camHUD];

				numScore.setGraphicSize(Std.int(numScore.width * STYLE.scale));

				numScore.updateHitbox();

				numScore.x = rating.x + (43 * daLoop) - ((numScore.width * seperatedScore.length) / 2) + 25;
				numScore.y = rating.y + 100;

				if (STYLE.antialiasing == false)
					numScore.antialiasing = false;

				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);
				numScore.moves = true;

				lastScore.push(numScore);
				insert(PlayState.instance.members.indexOf(notes), numScore);

				createTween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						remove(numScore);
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.002 * Math.pow(songMultiplier, 2)
				});

				daLoop++;
			}
		}

		createTween(rating, {alpha: 0}, 0.2, {
			startDelay: (Conductor.crochet * Math.pow(songMultiplier, 2)) * 0.001
		});

		createTween(currentTimingShown, {alpha: 0}, 0.1, {
			startDelay: (Conductor.crochet * Math.pow(songMultiplier, 2)) * 0.0005
		});
	}

	public function NearlyEquals(value1:Float, value2:Float, unimportantDifference:Float = 10):Bool
	{
		return Math.abs(FlxMath.roundDecimal(value1, 1) - FlxMath.roundDecimal(value2, 1)) < unimportantDifference;
	}

	var upHold:Bool = false;
	var downHold:Bool = false;
	var rightHold:Bool = false;
	var leftHold:Bool = false;

	// THIS FUNCTION JUST FUCKS WIT HELD NOTES AND BOTPLAY/REPLAY (also gamepad shit)

	private function keyShit():Void
	{
		var holdArray:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		var pressArray:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];
		var releaseArray:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];
		var keynameArray:Array<String> = ['left', 'down', 'up', 'right'];
		#if FEATURE_LUAMODCHART
		if (luaModchart != null)
		{
			for (i in 0...pressArray.length)
			{
				if (pressArray[i] == true)
				{
					luaModchart.executeState('onKeyPressed', [keynameArray[i]]);
				}
			};

			for (i in 0...releaseArray.length)
			{
				if (releaseArray[i] == true)
				{
					luaModchart.executeState('onKeyReleased', [keynameArray[i]]);
				}
			};
		};
		#end

		// Prevent player input if botplay is on
		if (PlayStateChangeables.botPlay)
		{
			holdArray = [false, false, false, false];
			pressArray = [false, false, false, false];
			releaseArray = [false, false, false, false];
		}

		if (FlxG.save.data.hitSound != 0 && pressArray.contains(true))
		{
			if (FlxG.save.data.strumHit)
			{
				var daHitSound:FlxSound = new FlxSound().loadEmbedded(Paths.sound('hitsounds/${HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase()}',
					'shared'));
				daHitSound.volume = FlxG.save.data.hitVolume;
				daHitSound.play();
			}
		}

		playerStrums.forEach(function(spr:StaticArrow)
		{
			if (!PlayStateChangeables.botPlay)
			{
				if (keys[spr.ID]
					&& spr.animation.curAnim.name != 'confirm'
					&& spr.animation.curAnim.name != 'pressed'
					&& !spr.animation.curAnim.name.startsWith('dirCon'))
				{
					spr.playAnim('pressed', false);
					if (spr.animation.curAnim.name == 'pressed' && spr.animation.curAnim.finished)
						spr.animation.curAnim.pause();
				}
				if (!keys[spr.ID])
				{
					spr.playAnim('static', false);
					spr.localAngle = 0;
				}
			}
		});
	}

	public function changeScrollSpeed(mult:Float, time:Float, ease):Void
	{
		var newSpeed = 1 * mult;
		if (time <= 0)
		{
			scrollSpeed = newSpeed;
		}
		else
		{
			scrollTween = createTween(this, {scrollSpeed: newSpeed}, time, {
				ease: ease,
				onUpdate: function(twn:FlxTween)
				{
					mult = scrollSpeed / FlxG.save.data.scrollSpeed;
					scrollMult = mult;
				},
				onComplete: function(twn:FlxTween)
				{
					scrollTween = null;
				}
			});
		}

		speedChanged = true;

		scrollMult = mult;
	}

	function noteMiss(direction:Int = 1, ?daNote:Note):Void
	{
		if (daNote.causesMisses)
		{
			if (gf != null && combo > 5 && gf.animOffsets.exists('sad') && !PlayStateChangeables.opponentMode)
			{
				gf.playAnim('sad');
			}
			if (combo != 0)
			{
				combo = 0;
			}

			if (!endingSong)
			{
				misses++;
			}

			daNote.rating = Ratings.timingWindows[0];

			totalNotesHit -= 1;
			totalPlayed += 1;

			songScore -= 10;

			if (FlxG.save.data.missSounds)
			{
				var styleShit:String = (STYLE.style == null ? 'default' : STYLE.style).toLowerCase();
				FlxG.sound.play(Paths.soundRandom('styles/$styleShit/missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			}

			if (!PlayStateChangeables.opponentMode)
				boyfriend.playAnim('sing' + dataSuffix[direction] + 'miss', true);
			else if (PlayStateChangeables.opponentMode && dad.animOffsets.exists('sing' + dataSuffix[direction] + 'miss'))
				dad.playAnim('sing' + dataSuffix[direction] + 'miss', true);

			#if FEATURE_LUAMODCHART
			if (luaModchart != null)
				luaModchart.executeState('playerOneMiss', [direction, Conductor.songPosition]);
			#end
			#if FEATURE_HSCRIPT
			scripts.executeAllFunc("noteMiss", [daNote]);
			#end

			health -= (daNote.missHealth * PlayStateChangeables.healthLoss);

			if (PlayStateChangeables.skillIssue)
				health = 0;
			if (!SONG.splitVoiceTracks)
				vocals.volume = 0;
			else
				vocalsPlayer.volume = 0;
			updateAccuracy();
			updateScoreText();
		}
	}

	function updateAccuracy()
	{
		accuracy = Math.max(0, totalNotesHit / totalPlayed * 100);
		accuracyDefault = Math.max(0, totalNotesHitDefault / totalPlayed * 100);
		#if FEATURE_HSCRIPT
		if (ScriptUtil.hasPause(scripts.executeAllFunc("updateAccuracy")))
			return;
		#end

		#if FEATURE_DISCORD
		// Updating Discord Rich Presence (with Time Left)
		Discord.changePresence(detailsText
			+ " "
			+ SONG.songName
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"\nAcc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC);
		#end

		judgementCounter.text = '';

		var timingWins = Ratings.timingWindows.copy();
		timingWins.reverse();

		for (rating in timingWins)
			judgementCounter.text += '${rating.name}s: ${rating.count}\n';

		judgementCounter.text += 'Misses: ${misses}';

		judgementCounter.updateHitbox();
	}

	function updateScoreText()
	{
		scoreTxt.text = Ratings.CalculateRanking(songScore, songScoreDef, nps, maxNPS,
			(FlxG.save.data.roundAccuracy ? FlxMath.roundDecimal(accuracy, 0) : accuracy));
		scoreTxt.screenCenter(X);
		scoreTxt.updateHitbox();
	}

	function receptorTween()
	{
		for (i in 0...strumLineNotes.length)
		{
			createTween(strumLineNotes.members[i], {modAngle: strumLineNotes.members[i].modAngle + 360}, 0.5 / songMultiplier,
				{ease: FlxEase.smootherStepInOut});
		}
	}

	function getKeyPresses(note:Note):Int
	{
		var possibleNotes:Array<Note> = [];

		notes.forEachAlive(function(daNote:Note)
		{
			if (daNote.canBeHit && daNote.mustPress)
			{
				possibleNotes.push(daNote);
				possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
			}
		});
		if (possibleNotes.length == 1)
			return possibleNotes.length + 1;
		return possibleNotes.length;
	}

	var mashing:Int = 0;
	var mashViolations:Int = 0;
	var etternaModeScore:Int = 0;

	function opponentNoteHit(daNote:Note):Void
	{
		if (SONG.songId != 'tutorial')
			camZooming = FlxG.save.data.camzoom;
		// come back to this later
		var altAnim:String = "";

		// askl

		if (daNote.noteShit.toLowerCase() == 'alt')
		{
			altAnim = '-alt';
		}
		if (!daNote.wasGoodHit)
		{
			if (daNote.isParent)
				for (i in daNote.children)
					i.sustainActive = true;

			if (PlayStateChangeables.healthDrain)
			{
				if (!daNote.isSustainNote)
				{
					updateScoreText();
					health -= 0.04 * PlayStateChangeables.healthLoss;
					if (health <= 0.01)
					{
						health = 0.01;
					}
				}
			}

			if (!daNote.isSustainEnd)
			{
				var singData:Int = Std.int(Math.abs(daNote.noteData));

				if (daNote.canPlayAnims)
				{
					var char:Character = dad;
					if (PlayStateChangeables.opponentMode)
						char = boyfriend;

					if (daNote.noteShit.toLowerCase() == 'gf' && gf != null)
						char = gf;

					char.playAnim('sing' + dataSuffix[daNote.noteData] + altAnim, true);
					char.holdTimer = 0;
				}

				if (FlxG.save.data.cpuStrums)
				{
					cpuStrums.forEach(function(spr:StaticArrow)
					{
						pressArrow(spr, spr.ID, daNote);
					});
				}

				if (SONG.needsVoices)
				{
					if (!SONG.splitVoiceTracks)
						vocals.volume = 1;
					else
						vocalsEnemy.volume = 1;
				}
			}

			if (!daNote.isSustainNote)
			{
				if (FlxG.save.data.cpuStrums)
				{
					if (FlxG.save.data.cpuSplash && daNote.canNoteSplash && !PlayStateChangeables.middleScroll)
					{
						spawnNoteSplashOnNote(daNote);
					}
				}
			}

			#if FEATURE_LUAMODCHART
			if (luaModchart != null)
				if (!PlayStateChangeables.opponentMode)
					luaModchart.executeState('playerTwoSing', [Math.abs(daNote.noteData), Conductor.songPosition]);
				else
					luaModchart.executeState('playerOneSing', [Math.abs(daNote.noteData), Conductor.songPosition]);
			#end

			#if FEATURE_HSCRIPT
			scripts.executeAllFunc("opponentNoteHit", [daNote]);
			#end

			if (!daNote.isSustainNote)
				destroyNote(daNote);

			daNote.wasGoodHit = true;
		}
	}

	function goodNoteHit(note:Note, resetMashViolation = true):Void
	{
		if (PlayStateChangeables.opponentMode)
			camZooming = FlxG.save.data.camzoom;

		if (mashing != 0)
			mashing = 0;

		// add newest note to front of notesHitArray
		// the oldest notes are at the end and are removed first

		if (!note.isSustainNote)
		{
			var noteDate:Date = Date.now();
			notesHitArray.unshift(noteDate.getTime());
		}

		if (!resetMashViolation && mashViolations >= 1)
			mashViolations--;

		if (mashViolations < 0)
			mashViolations = 0;

		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				if (FlxG.save.data.hitSound != 0)
				{
					if (!FlxG.save.data.strumHit)
					{
						var daHitSound:FlxSound = new FlxSound()
							.loadEmbedded(Paths.sound('hitsounds/${HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase()}', 'shared'));
						daHitSound.volume = FlxG.save.data.hitVolume;
						daHitSound.play();
					}
				}
				/* Enable Sustains to be hit. 
					// This is to prevent hitting sustains if you hold a strum before the note is coming without hitting the note parent. 
					(I really hope I made me understand lol.) */
				if (note.isParent)
					for (i in note.children)
						i.sustainActive = true;

				if (note.canRate)
				{
					combo += 1;
					popUpScore(note);
				}
			}

			switch (note.noteShit.toLowerCase())
			{
				case 'hurt':
					if (FlxG.save.data.notesplashes && !note.isSustainNote)
					{
						spawnNoteSplashOnNote(note);
					}
					if (FlxG.save.data.accuracyMod == 0)
						totalNotesHit -= 1;
					note.rating = Ratings.timingWindows[0];
					health -= 0.8;
					boyfriend.playAnim('hurt');
			}

			var altAnim:String = "";
			if (note.noteShit.toLowerCase() == 'alt')
			{
				altAnim = '-alt';
			}

			if (note.canPlayAnims)
			{
				var char:Character = boyfriend;
				if (PlayStateChangeables.opponentMode)
					char = dad;

				if (note.noteShit.toLowerCase() == 'gf' && gf != null)
					char = gf;

				char.playAnim('sing' + dataSuffix[note.noteData] + altAnim, true);
				char.holdTimer = 0;
			}

			#if FEATURE_LUAMODCHART
			if (luaModchart != null)
				if (!PlayStateChangeables.opponentMode)
					luaModchart.executeState('playerOneSing', [Math.abs(note.noteData), Conductor.songPosition]);
				else
					luaModchart.executeState('playerTwoSing', [Math.abs(note.noteData), Conductor.songPosition]);
			#end

			#if FEATURE_HSCRIPT
			scripts.executeAllFunc("goodNoteHit", [note]);
			#end

			playerStrums.forEach(function(spr:StaticArrow)
			{
				pressArrow(spr, spr.ID, note);
			});

			if (!note.isSustainNote)
			{
				destroyNote(note);
				updateAccuracy();
				updateScoreText();
			}

			if (SONG.splitVoiceTracks != true)
				vocals.volume = 1;
			else
				vocalsPlayer.volume = 1;

			note.wasGoodHit = true;
		}
	}

	function pressArrow(spr:StaticArrow, idCheck:Int, daNote:Note)
	{
		if (Math.abs(daNote.noteData) == idCheck)
		{
			if (!FlxG.save.data.stepMania)
			{
				spr.playAnim('confirm', true);

				spr.animation.finishCallback = function(name)
				{
					if (daNote.mustPress && PlayStateChangeables.botPlay)
					{
						spr.playAnim('static', true);
					}
					else if (!daNote.mustPress)
					{
						if (FlxG.save.data.cpuStrums)
						{
							spr.playAnim('static', true);
						}
					}
				}
			}
			else
			{
				spr.localAngle = daNote.originAngle;
				spr.playAnim('dirCon' + daNote.originColor, true);
				spr.animation.finishCallback = function(name)
				{
					if (daNote.mustPress && PlayStateChangeables.botPlay)
					{
						spr.localAngle = 0;
						spr.playAnim('static', true);
					}
					else if (!daNote.mustPress)
					{
						if (FlxG.save.data.cpuStrums)
						{
							spr.localAngle = 0;
							spr.playAnim('static', true);
						}
					}
				}
			}
		}
	}

	var danced:Bool = false;

	override function stepHit()
	{
		super.stepHit();
		if (!paused)
		{
			var bpmRatio:Float = Conductor.bpm / 100;
			if (Math.abs(Conductor.songPosition * songMultiplier) > Math.abs(inst.time + (25 * bpmRatio))
				|| Math.abs(Conductor.songPosition * songMultiplier) < Math.abs(inst.time - (25 * bpmRatio)))
			{
				resyncVocals();
			}
		}

		if (!endingSong && currentSection != null)
		{
			if (allowedToHeadbang && curStep % 4 == 0)
			{
				if (gf != null)
					gf.dance();
			}
		}

		// HARDCODING FOR MILF ZOOMS!
		if (PlayState.SONG.songId == 'milf' && curStep >= 672 && curStep < 800 && camZooming)
		{
			zoomMultiplier += 0.02;
			if (curStep % 4 == 0)
			{
				FlxG.camera.zoom += 0.015 * zoomMultiplier;
				camHUD.zoom += 0.05 * zoomMultiplier;
			}
		}
		if (PlayState.SONG.songId == 'milf' && curStep >= 800)
			zoomMultiplier = 1;

		#if FEATURE_LUAMODCHART
		if (executeModchart && luaModchart != null)
		{
			luaModchart.setVar('curStep', curStep);
			luaModchart.executeState('stepHit', [curStep]);
		}
		#end

		#if FEATURE_HSCRIPT
		scripts.setAll("curStep", curStep);
		scripts.executeAllFunc("stepHit", [curStep]);
		#end

		if (!FlxG.save.data.motion && !paused)
		{
			if (curStep % 4 == 0)
			{
				iconP1.scale.set(1.1, 1.1);
				iconP2.scale.set(1.1, 1.1);

				iconP1.updateHitbox();
				iconP2.updateHitbox();
			}
		}

		if (isStoryMode)
		{
			if (SONG.songId == 'eggnog' && curStep == 938 * songMultiplier)
			{
				var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
					-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
				blackShit.scrollFactor.set();
				add(blackShit);
				camHUD.visible = false;
				camStrums.visible = false;

				FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				createTimer(3, function(tmr)
				{
					endSong();
				});
			}
		}

		if (curStep % 32 == 28 #if cpp && curStep != 316 #end && SONG.songId == 'bopeebo')
		{
			boyfriend.playAnim('hey', true);
			if (gf != null)
				gf.playAnim('cheer', true);
		}
		if ((curStep == 190 * songMultiplier || curStep == 446 * songMultiplier) && SONG.songId == 'bopeebo')
		{
			boyfriend.playAnim('hey', true);
			if (gf != null)
				gf.playAnim('cheer', true);
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, (PlayStateChangeables.useDownscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING));
		}

		#if FEATURE_LUAMODCHART
		if (executeModchart && luaModchart != null)
		{
			luaModchart.executeState('beatHit', [curBeat]);
		}
		#end

		#if FEATURE_HSCRIPT
		scripts.setAll("curBeat", curBeat);
		scripts.executeAllFunc("beatHit", [beatHit]);
		#end

		var bpmRatio = SONG.bpm / 100;
		if (currentSection != null)
		{
			if (curBeat % idleBeat == 0)
			{
				for (boey in dadGroup.members)
				{
					if (idleToBeat && !boey.animation.curAnim.name.startsWith('sing'))
						boey.dance(forcedToIdle);
				}

				for (boi in boyfriendGroup.members)
				{
					if (idleToBeat && !boi.animation.curAnim.name.startsWith('sing'))
						boi.dance(forcedToIdle);
				}
			}
			else if (curBeat % idleBeat != 0)
			{
				for (boey in dadGroup.members)
				{
					if (boey.isDancing && !boey.animation.curAnim.name.startsWith('sing'))
						boey.dance(forcedToIdle);
				}
				for (boi in boyfriendGroup.members)
				{
					if (boi.isDancing && !boi.animation.curAnim.name.startsWith('sing'))
						boi.dance(forcedToIdle);
				}
			}
		}

		wiggleShit.update(Conductor.crochet);

		if (!endingSong && currentSection != null)
		{
			if (!SONG.splitVoiceTracks)
			{
				if (vocals.volume == 0 && !currentSection.playerSec)
					vocals.volume = 1;
			}
			else
			{
				if (vocalsPlayer.volume == 0 && !currentSection.playerSec)
					vocalsPlayer.volume = 1;
			}
		}
	}

	override function sectionHit():Void
	{
		super.sectionHit();

		if (camZooming && FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		#if FEATURE_LUAMODCHART
		if (currentSection != null)
			if (luaModchart != null)
				luaModchart.setVar("mustHit", currentSection.playerSec);
		#end

		#if FEATURE_HSCRIPT
		scripts.setAll("curSection", curSection);
		scripts.executeAllFunc("sectionHit", [curSection]);
		#end

		changeCameraFocus();
	}

	function changeCameraFocus()
	{
		try
		{
			if (currentSection != null)
			{
				var offsetX = 0;
				var offsetY = 0;
				if (!currentSection.playerSec
					&& (camFollow.x != dad.getMidpoint().x + dad.camPos[0] + offsetX
						&& camFollow.y != dad.getMidpoint().y + dad.camPos[1] + offsetY))
				{
					#if FEATURE_LUAMODCHART
					if (luaModchart != null)
					{
						offsetX = luaModchart.getVar("followXOffset", "float");
						offsetY = luaModchart.getVar("followYOffset", "float");
					}
					#end
					if (!Stage.staticCam)
					{
						camFollow.setPosition(dad.getMidpoint().x + dad.camPos[0] + offsetX, dad.getMidpoint().y + dad.camPos[1] + offsetY);
					}
					#if FEATURE_LUAMODCHART
					if (luaModchart != null)
						luaModchart.executeState('playerTwoTurn', []);
					#end

					#if FEATURE_HSCRIPT
					scripts.executeAllFunc("playerTwoTurn");
					#end
					// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);

					switch (dad.curCharacter)
					{
						case 'mom' | 'mom-car':
							camFollow.y = dad.getMidpoint().y;
					}
				}

				if (currentSection.playerSec
					&& (camFollow.x != boyfriend.getMidpoint().x + boyfriend.camPos[0] + offsetX
						&& camFollow.y != boyfriend.getMidpoint().y + boyfriend.camPos[1] + offsetY))
				{
					#if FEATURE_LUAMODCHART
					if (luaModchart != null)
					{
						offsetX = luaModchart.getVar("followXOffset", "float");
						offsetY = luaModchart.getVar("followYOffset", "float");
					}
					#end
					if (!Stage.staticCam)
					{
						camFollow.setPosition(boyfriend.getMidpoint().x + boyfriend.camPos[0] + offsetX,
							boyfriend.getMidpoint().y + boyfriend.camPos[1] + offsetY);
					}

					#if FEATURE_LUAMODCHART
					if (luaModchart != null)
						luaModchart.executeState('playerOneTurn', []);
					#end

					#if FEATURE_HSCRIPT
					scripts.executeAllFunc("playerOneTurn");
					#end
					switch (Stage.curStage)
					{
						case 'limo':
							camFollow.x = boyfriend.getMidpoint().x - 300;
						case 'mall':
							camFollow.y = boyfriend.getMidpoint().y - 200;
					}
				}
			}
		}
		catch (e)
		{
		}
	}

	public function cacheCharacter(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					newDad.alpha = 0.00001;
				}

			case 1:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
				}
		}
	}

	public function changeChar(type:Int, value:String, x:Float, y:Float)
	{
		switch (type)
		{
			case 0:
				if (dad.curCharacter != value)
				{
					var lastAlpha:Float = dad.alpha;
					dad.alpha = 0.00001;
					dad = dadMap.get(value);
					dad.setPosition(x, y);
					dad.alpha = lastAlpha;
				}
			case 1:
				if (boyfriend.curCharacter != value)
				{
					var lastAlpha:Float = boyfriend.alpha;
					boyfriend.alpha = 0.00001;
					boyfriend = boyfriendMap.get(value);
					boyfriend.setPosition(x, y);
					boyfriend.alpha = lastAlpha;
				}
		}
	}

	public var cleanedSong:SongData;

	function poggers(?cleanTheSong = false)
	{
		var notes = [];

		if (cleanTheSong)
		{
			cleanedSong = SONG;

			for (section in cleanedSong.notes)
			{
				var removed = [];

				for (note in section.sectionNotes)
				{
					var old = note[0];
					if (note[0] < section.startTime)
					{
						notes.push(note);
						removed.push(note);
					}
					if (note[0] > section.endTime)
					{
						notes.push(note);
						removed.push(note);
					}
				}

				for (i in removed)
				{
					section.sectionNotes.remove(i);
				}
			}

			for (section in cleanedSong.notes)
			{
				var saveRemove = [];

				for (i in notes)
				{
					if (i[0] >= section.startTime && i[0] < section.endTime)
					{
						saveRemove.push(i);
						section.sectionNotes.push(i);
					}
				}

				for (i in saveRemove)
					notes.remove(i);
			}

			SONG = cleanedSong;
		}
		else
		{
			for (section in SONG.notes)
			{
				var removed = [];

				for (note in section.sectionNotes)
				{
					var old = note[0];
					if (note[0] < section.startTime)
					{
						notes.push(note);
						removed.push(note);
					}
					if (note[0] > section.endTime)
					{
						notes.push(note);
						removed.push(note);
					}
				}

				for (i in removed)
				{
					section.sectionNotes.remove(i);
				}
			}

			for (section in SONG.notes)
			{
				var saveRemove = [];

				for (i in notes)
				{
					if (i[0] >= section.startTime && i[0] < section.endTime)
					{
						saveRemove.push(i);
						section.sectionNotes.push(i);
					}
				}

				for (i in saveRemove)
					notes.remove(i);
			}

			SONG = cleanedSong;
		}
	}

	override function destroy()
	{
		#if FEATURE_HSCRIPT
		if (scripts != null)
		{
			scripts.active = false;
			scripts.destroy();
			scripts = null;
		}
		#end

		Lib.current.stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleInput);
		Lib.current.stage.removeEventListener(KeyboardEvent.KEY_UP, releaseInput);

		#if FEATURE_LUAMODCHART
		if (luaModchart != null)
		{
			luaModchart.die();
			luaModchart = null;
		}

		noteskinSprite = null;
		cpuNoteskinSprite = null;

		LuaStorage.ListOfCameras.resize(0);

		LuaStorage.objectProperties.clear();

		LuaStorage.objects.clear();
		#end

		cleanPlayObjects();

		super.destroy();
	}

	public function updateSettings():Void
	{
		scoreTxt.y = healthBarBG.y;
		if (FlxG.save.data.colour)
		{
			if (!PlayStateChangeables.opponentMode)
				healthBar.createFilledBar(dad.barColor, boyfriend.barColor);
			else
				healthBar.createFilledBar(boyfriend.barColor, dad.barColor);
		}
		else
		{
			if (!PlayStateChangeables.opponentMode)
				healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
			else
				healthBar.createFilledBar(0xFF66FF33, 0xFFFF0000);
		}
		healthBar.updateBar();

		PlayStateChangeables.botPlay = FlxG.save.data.botplay;

		for (i in uiGroup)
		{
			i.kill();
			uiGroup.remove(i);
		}

		if (songStarted)
		{
			songName.visible = FlxG.save.data.songPosition;
			songPosBar.visible = FlxG.save.data.songPosition;
			bar.visible = FlxG.save.data.songPosition;
			if (FlxG.save.data.songPosition)
			{
				songName.revive();
				songPosBar.revive();
				bar.revive();
				uiGroup.add(songPosBar);
				uiGroup.add(songName);
				uiGroup.add(bar);
				songName.alpha = 1;
				songPosBar.alpha = 0.85;
				bar.alpha = 1;
			}
		}

		if (PlayStateChangeables.botPlay)
		{
			botPlayState.revive();
			uiGroup.add(botPlayState);
			usedBot = true;
		}

		if (FlxG.save.data.judgementCounter)
		{
			judgementCounter.revive();
			uiGroup.add(judgementCounter);
		}

		if (FlxG.save.data.healthBar)
		{
			healthBarBG.revive();
			healthBar.revive();
			iconP1.revive();
			iconP2.revive();
			uiGroup.add(healthBarBG);
			uiGroup.add(healthBar);
			uiGroup.add(iconP1);
			uiGroup.add(iconP2);
			scoreTxt.y = healthBarBG.y + 47;
		}

		scoreTxt.revive();
		uiGroup.add(scoreTxt);
	}

	function HealthDrain():Void
	{
		// FlxG.sound.play(Paths.sound("Vine Boom"), 2);
		// boyfriend.playAnim("hit", true);
		new FlxTimer().start(0.01, function(tmr:FlxTimer)
		{
			health -= 0.005;
		}, 300);
	}

	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null)
		{
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	function ttweenCamIn():Void
	{
		createTween(FlxG.camera, {zoom: 2}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	#if FEATURE_HSCRIPT
	function initScripts()
	{
		if (scripts == null)
			return;

		var scriptData:Map<String, String> = [];

		var files:Array<String> = [];
		var extensions = ["hx", "hscript", "hsc", "hxs"];
		var rawFiles:Array<String> = CoolUtil.readAssetsDirectoryFromLibrary('assets/shared/data/songs/${SONG.songId}', 'TEXT', 'default', false);

		for (sub in rawFiles)
		{
			for (ext in extensions)
				if (sub.contains(ext)) // Dont want the charts in there lmfao who made this function
					files.push(sub);
		}

		for (_ in CoolUtil.readAssetsDirectoryFromLibrary('assets/shared/data/scripts', 'TEXT', 'default', false))
		{
			for (ext in extensions)
				if (_.contains(ext))
					files.push(_);
		}

		if (FlxG.save.data.gen)
			Debug.logTrace(files);

		for (file in files)
		{
			var hx:Null<String> = null;

			if (OpenFlAssets.exists(file, TEXT))
				hx = OpenFlAssets.getText(file);

			if (hx != null)
			{
				var scriptName:String = CoolUtil.getFileStringFromPath(file);

				if (!scriptData.exists(scriptName))
				{
					scriptData.set(scriptName, hx);
				}
			}
		}

		for (scriptName => hx in scriptData)
		{
			if (scripts.getScriptByTag(scriptName) == null)
			{
				scripts.addScript(scriptName).executeString(hx);
			}
			else
			{
				scripts.getScriptByTag(scriptName).error("Duplicate Script Error!", '$scriptName: Duplicate Script');
			}
		}
	}

	function onAddScript(script:Script)
	{
		script.set("PlayState", PlayState);
		script.set("game", PlayState.instance);
		script.set("Debug", Debug);
		script.set("health", health);
		script.set("CoolUtil", CoolUtil);
		script.set("SONG", SONG);
		script.set("PlayStateChangeables", PlayStateChangeables);
		script.set("downScroll", PlayStateChangeables.useDownscroll);
		script.set("middleScroll", PlayStateChangeables.middleScroll);

		// FUNCTIONS

		//  CREATION FUNCTIONS
		script.set("create", function()
		{
		});
		script.set("createPost", function()
		{
		});

		//  COUNTDOWN
		script.set("countdown", function()
		{
		});
		script.set("countTick", function(?tick:Int)
		{
		});
		script.set("songMultiplier", songMultiplier);

		//  SONG FUNCTIONS
		script.set("startSong", function()
		{
		}); // ! HAS PAUSE
		script.set("endSong", function()
		{
		}); // ! HAS PAUSE
		script.set("beatHit", function(?beat:Int)
		{
		});
		script.set("stepHit", function(?step:Int)
		{
		});

		script.set("sectionHit", function(?section:Int)
		{
		});

		//  NOTE FUNCTIONS
		script.set("spawnNote", function(?note:Note)
		{
		}); // ! HAS PAUSE
		script.set("goodNoteHit", function(?note:Note)
		{
		});
		script.set("opponentNoteHit", function(?note:Note)
		{
		});
		script.set("noteMiss", function(?note:Note)
		{
		});

		script.set("playerOneTurn", function(?note:Note)
		{
		});
		script.set("playerTwoTurn", function(?note:Note)
		{
		});

		script.set("createTween", function(Object:Dynamic, Values:Dynamic, Duration:Float, ?Options:TweenOptions)
		{
		});
		script.set("createTweenNum", function(FromValue:Float, ToValue:Float, Duration:Float, ?Options:TweenOptions)
		{
		});
		// sex
		script.set("notesUpdate", function()
		{
		}); // ! HAS PAUSE

		script.set("ghostTap", function(?direction:Int)
		{
		});

		//  EVENT FUNCTIONS
		script.set("event", function(?event:String, ?val1:Dynamic, ?val2:Dynamic)
		{
		}); // ! HAS PAUSE

		//  PAUSING / RESUMING
		script.set("pause", function()
		{
		}); // ! HAS PAUSE
		script.set("resume", function()
		{
		}); // ! HAS PAUSE

		//  GAMEOVER
		script.set("gameOver", function()
		{
		}); // ! HAS PAUSE

		//  MISC
		script.set("update", function(elapsed:Float)
		{
		});
		script.set("updatePost", function(elapsed:Float)
		{
		});
		script.set("updateScore", function(?miss:Bool = false)
		{
		}); // ! HAS PAUSE

		// VARIABLES

		script.set("curStep", 0);
		script.set("curSection", 0);
		script.set("curBeat", 0);
		script.set("bpm", Conductor.bpm);

		// OBJECTS
		script.set("camGame", camGame);
		script.set("camHUD", camHUD);
		script.set("camFollow", camFollow);
		script.set("camZoom", zoomForTweens);

		// CHARACTERS
		script.set("boyfriend", boyfriend);
		script.set("dad", dad);
		script.set("gf", gf);

		// NOTES
		script.set("notes", notes);
		script.set("strumLineNotes", strumLineNotes);
		script.set("playerStrums", playerStrums);
		script.set("cpuStrums", cpuStrums);

		script.set("unspawnNotes", unspawnNotes);

		// MISC
		script.set("add", function(obj:FlxBasic, ?front:Bool = false)
		{
			if (front)
			{
				getInstance().add(obj);
			}
			else
			{
				if (PlayState.instance.isDead)
				{
					GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.bf), obj);
				}
				else
				{
					var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
					if (PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position)
					{
						position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
					}
					else if (PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position)
					{
						position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
					}
					PlayState.instance.insert(position, obj);
				}
			}
		});
	}
	#end

	public static inline function getInstance()
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}

	public function createTween(Object:Dynamic, Values:Dynamic, Duration:Float, ?Options:TweenOptions):FlxTween
	{
		var tween:FlxTween = tweenManager.tween(Object, Values, Duration, Options);
		tween.manager = tweenManager;
		return tween;

		#if FEATURE_HSCRIPT
		scripts.executeAllFunc("createTween", [Object, Values, Duration, Options]);
		#end
	}

	public function createTweenNum(FromValue:Float, ToValue:Float, Duration:Float = 1, ?Options:TweenOptions, ?TweenFunction:Float->Void):FlxTween
	{
		var tween:FlxTween = tweenManager.num(FromValue, ToValue, Duration, Options, TweenFunction);
		tween.manager = tweenManager;
		return tween;

		#if FEATURE_HSCRIPT
		scripts.executeAllFunc("createTweenNum", [FromValue, ToValue, Duration, Options, TweenFunction]);
		#end
	}

	public function createTimer(Time:Float = 1, ?OnComplete:FlxTimer->Void, Loops:Int = 1):FlxTimer
	{
		var timer:FlxTimer = new FlxTimer();
		timer.manager = timerManager;
		return timer.start(Time, OnComplete, Loops);
	}

	public function precacheThing(target:String, type:String, ?library:String = null)
	{
		switch (type)
		{
			case 'image':
				Paths.image(target, library);
			case 'sound':
				Paths.sound(target, library);
			case 'music':
				Paths.music(target, library);
		}
	}

	// https://github.com/ShadowMario/FNF-PsychEngine/pull/9015
	// Seems like a good pull request. Credits: Raltyro.
	private function cachePopUpScore()
	{
		var styleShit:String = (STYLE.style == null ? 'default' : STYLE.style).toLowerCase();

		for (precaching in Ratings.timingWindows)
			Paths.image('hud/$styleShit/${precaching.name.toLowerCase()}', 'shared');

		for (i in 0...10)
		{
			Paths.image('hud/$styleShit/num$i', 'shared');
		}
	}

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['ready', 'set', 'go']);

		var styleShit:String = (STYLE.style == null ? 'default' : STYLE.style).toLowerCase();
		var introAlts = ['hud/$styleShit/ready', 'hud/$styleShit/set', 'hud/$styleShit/go'];

		for (asset in introAlts)
			Paths.image(asset);

		var things:Array<String> = ['intro3', 'intro2', 'intro1', 'introGo'];
		for (precaching in things)
			Paths.sound('styles/$styleShit/$precaching');
	}

	public static function getFlxEaseByString(?ease:String = '')
	{
		switch (ease.toLowerCase().trim())
		{
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepInOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	public function hideHUD(hidden:Bool)
	{
		if (hidden)
		{
			healthBarBG.visible = false;
			healthBar.visible = false;
			iconP1.visible = false;
			iconP2.visible = false;
			scoreTxt.visible = false;
			songName.visible = false;
			songPosBar.visible = false;
			bar.visible = false;
			judgementCounter.visible = false;
		}
		else
		{
			healthBarBG.visible = true;
			healthBar.visible = true;
			iconP1.visible = true;
			iconP2.visible = true;
			scoreTxt.visible = true;
			songName.visible = FlxG.save.data.songPosition;
			songPosBar.visible = FlxG.save.data.songPosition;
			bar.visible = FlxG.save.data.songPosition;
			judgementCounter.visible = FlxG.save.data.judgementCounter;
		}
	}

	function removeStaticArrows(?destroy:Bool = false)
	{
		if (arrowsGenerated)
		{
			arrowLanes.forEach(function(bgLane:FlxSprite)
			{
				arrowLanes.remove(bgLane, true);
				if (destroy)
					arrowLanes.destroy();
			});

			playerStrums.forEach(function(babyArrow:StaticArrow)
			{
				playerStrums.remove(babyArrow);
				if (destroy)
					babyArrow.destroy();
			});
			cpuStrums.forEach(function(babyArrow:StaticArrow)
			{
				cpuStrums.remove(babyArrow);
				if (destroy)
					babyArrow.destroy();
			});
			strumLineNotes.forEach(function(babyArrow:StaticArrow)
			{
				strumLineNotes.remove(babyArrow);
				if (destroy)
					babyArrow.destroy();
			});
			arrowsGenerated = false;
		}
	}

	function changeNoteSkins(isStrum:Bool, isPlayer:Bool, texture:String)
	{
		switch (isStrum)
		{
			case true:
				switch (isPlayer)
				{
					case true:
						for (i in 0...playerStrums.length)
						{
							playerStrums.members[i].texture = 'noteskins/' + texture;
						}
					case false:
						for (i in 0...cpuStrums.length)
						{
							cpuStrums.members[i].texture = 'noteskins/' + texture;
						}
				}
			case false:
				switch (isPlayer)
				{
					case true:
						for (note in unspawnNotes)
						{
							if (note.mustPress && (note.noteShit == null || note.noteShit.toLowerCase() == 'normal'))
							{
								note.texture = 'noteskins/' + texture;
							}
						}

						for (note in notes)
						{
							if (note.mustPress && (note.noteShit == null || note.noteShit.toLowerCase() == 'normal'))
							{
								note.texture = 'noteskins/' + texture;
							}
						}
					case false:
						for (note in unspawnNotes)
						{
							if (!note.mustPress && (note.noteShit == null || note.noteShit.toLowerCase() == 'normal'))
							{
								note.texture = 'noteskins/' + texture;
							}
						}

						for (note in notes)
						{
							if (!note.mustPress && (note.noteShit == null || note.noteShit.toLowerCase() == 'normal'))
							{
								note.texture = 'noteskins/' + texture;
							}
						}
				}
		}
	}

	private function addSongTiming()
	{
		TimingStruct.clearTimings();

		var currentIndex = 0;
		for (i in SONG.eventObjects)
		{
			if (i.type == "BPM Change")
			{
				var beat:Float = i.position;

				var endBeat:Float = Math.POSITIVE_INFINITY;

				var bpm = i.value * songMultiplier;

				TimingStruct.addTiming(beat, bpm, endBeat, 0); // offset in this case = start time since we don't have a offset

				if (currentIndex != 0)
				{
					var data = TimingStruct.AllTimings[currentIndex - 1];
					data.endBeat = beat;
					data.length = ((data.endBeat - (data.startBeat)) / (data.bpm / 60));
					var step = ((60 / (data.bpm)) * 1000) / 4;
					TimingStruct.AllTimings[currentIndex].startStep = Math.floor((((data.endBeat / (data.bpm / 60)) * 1000) / step));
					TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
				}

				currentIndex++;
			}
		}
		recalculateAllSectionTimes();
	}

	private function destroyNote(daNote:Note)
	{
		if (daNote == null)
			return;

		daNote.active = false;
		daNote.visible = false;
		daNote.kill();
		notes.remove(daNote, true);
		daNote.destroy();
		daNote = null;
	}

	private function cleanPlayObjects()
	{
		timerManager.clear();

		tweenManager.clear();

		while (unspawnNotes.length > 0)
		{
			var note = unspawnNotes[0];
			unspawnNotes.remove(note);

			if (!note.isParent && !note.isSustainNote)
			{
				#if FEATURE_LUAMODCHART
				note.LuaNote = null;
				#end

				note = null;

				return;
			}

			if (note.isSustainNote)
			{
				for (susDef in note.parent.children)
				{
					#if FEATURE_LUAMODCHART
					susDef.LuaNote = null;
					#end
					susDef = null;
				}
				#if FEATURE_LUAMODCHART
				note.parent.LuaNote = null;
				#end
				note.parent = null;

				return;
			}
		}

		for (i in uiGroup)
		{
			i.kill();
			uiGroup.remove(i);
		}
		uiGroup.clear();

		boyfriendGroup.clear();
		dadGroup.clear();
		if (gfGroup != null)
			gfGroup.clear();

		boyfriend.destroy();
		dad.destroy();
		if (gf != null)
			gf.destroy();

		boyfriend = null;
		dad = null;
		if (gf != null)
			gf = null;

		Stage.destroy();
		Stage = null;
	}

	public function playVideo(name:String)
	{
		#if VIDEOS
		inCutscene = true;
		inCinematic = true;

		var filepath:String = Paths.video(name);
		if (!OpenFlAssets.exists(filepath))
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:VideoHandler = new VideoHandler();
		video.load(filepath);
		// Recent versions
		video.play();
		video.onEndReached.add(function()
		{
			video.dispose();
			startAndEnd();
			return;
		}, true);
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	public function startAndEnd()
	{
		if (endingSong)
			endSong();
		else
			startCountdown();
	}

	function playCutscene(name:String, ?atend:Bool)
	{
		#if VIDEOS
		inCutscene = true;
		inCinematic = true;
		var diff:String = CoolUtil.getSuffixFromDiff(CoolUtil.difficultyArray[storyDifficulty]);
		cutscene = new VideoHandler();
		cutscene.load(Paths.video(name));
		inst.stop();
		cutscene.onEndReached.add(function()
		{
			inCutscene = false;
			if (atend == true)
			{
				if (storyPlaylist.length <= 0)
					LoadingState.loadAndSwitchState(new StoryMenuState());
				else
				{
					SONG = Song.loadFromJson(storyPlaylist[0].toLowerCase(), diff);
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				createTimer(0.5, function(timer)
				{
					startCountdown();
				});
			}

			cutscene.dispose();
		});

		new FlxTimer().start(0.001, function(tmr:FlxTimer):Void
		{
			cutscene.play();
		});
		#else
		FlxG.log.warn("Platform Not Supported.");
		#end
	}
}
