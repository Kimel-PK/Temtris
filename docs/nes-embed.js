var SCREEN_WIDTH = 256;
var SCREEN_HEIGHT = 240;
var FRAMEBUFFER_SIZE = SCREEN_WIDTH*SCREEN_HEIGHT;

var canvas_ctx, image;
var framebuffer_u8, framebuffer_u32;

var AUDIO_BUFFERING = 512;
var SAMPLE_COUNT = 4*1024;
var SAMPLE_MASK = SAMPLE_COUNT - 1;
var audio_samples_L = new Float32Array(SAMPLE_COUNT);
var audio_samples_R = new Float32Array(SAMPLE_COUNT);
var audio_write_cursor = 0, audio_read_cursor = 0;

var volume = 160;

var nes = new jsnes.NES({
	onFrame: function(framebuffer_24) {
		for(var i = 0; i < FRAMEBUFFER_SIZE; i++) framebuffer_u32[i] = 0xFF000000 | framebuffer_24[i];
		nes.papu.setMasterVolume(volume);
	},
	onAudioSample: function(l, r) {
		audio_samples_L[audio_write_cursor] = l;
		audio_samples_R[audio_write_cursor] = r;
		audio_write_cursor = (audio_write_cursor + 1) & SAMPLE_MASK;
	},
});

// https://stackoverflow.com/questions/3448347/how-to-scale-an-imagedata-in-html-canvas
function scaleImageData(imageData, scale) {
	var scaled = canvas_ctx.createImageData(imageData.width * scale, imageData.height * scale);
	
	for(var row = 0; row < imageData.height; row++) {
		for(var col = 0; col < imageData.width; col++) {
			var sourcePixel = [
				imageData.data[(row * imageData.width + col) * 4 + 0],
				imageData.data[(row * imageData.width + col) * 4 + 1],
				imageData.data[(row * imageData.width + col) * 4 + 2],
				imageData.data[(row * imageData.width + col) * 4 + 3]
			];
			for(var y = 0; y < scale; y++) {
				var destRow = row * scale + y;
				for(var x = 0; x < scale; x++) {
					var destCol = col * scale + x;
					for(var i = 0; i < 4; i++) {
						scaled.data[(destRow * scaled.width + destCol) * 4 + i] = sourcePixel[i];
					}
				}
			}
		}
	}
	
	return scaled;
}

function onAnimationFrame() {
	window.requestAnimationFrame(onAnimationFrame);
	
	image.data.set(framebuffer_u8);
	canvas_ctx.putImageData(scaleImageData (image, 2.0), 0, 0);
}

function audio_remain() {
	return (audio_write_cursor - audio_read_cursor) & SAMPLE_MASK;
}

function audio_callback(event) {
	var dst = event.outputBuffer;
	var len = dst.length;
	
	// Attempt to avoid buffer underruns.
	if(audio_remain() < AUDIO_BUFFERING) nes.frame();
	
	var dst_l = dst.getChannelData(0);
	var dst_r = dst.getChannelData(1);
	for(var i = 0; i < len; i++){
		var src_idx = (audio_read_cursor + i) & SAMPLE_MASK;
		dst_l[i] = audio_samples_L[src_idx];
		dst_r[i] = audio_samples_R[src_idx];
	}
	
	audio_read_cursor = (audio_read_cursor + len) & SAMPLE_MASK;
}

function keyboard(callback, event) {
	switch(event.keyCode) {
		case 38: // UP
			callback(1, jsnes.Controller.BUTTON_UP); break;
		case 40: // Down
			callback(1, jsnes.Controller.BUTTON_DOWN); break;
		case 37: // Left
			callback(1, jsnes.Controller.BUTTON_LEFT); break;
		case 39: // Right
			callback(1, jsnes.Controller.BUTTON_RIGHT); break;
		case 75: // B
			callback(1, jsnes.Controller.BUTTON_B); break;
		case 76: // A
			callback(1, jsnes.Controller.BUTTON_A); break;
			
		case 71: // UP
			callback(2, jsnes.Controller.BUTTON_UP); break;
		case 66: // Down
			callback(2, jsnes.Controller.BUTTON_DOWN); break;
		case 86: // Left
			callback(2, jsnes.Controller.BUTTON_LEFT); break;
		case 78: // Right
			callback(2, jsnes.Controller.BUTTON_RIGHT); break;
		case 90: // B
			callback(2, jsnes.Controller.BUTTON_B); break;
		case 88: // A
			callback(2, jsnes.Controller.BUTTON_A); break;
		
		case 16: // Select
			callback(1, jsnes.Controller.BUTTON_SELECT);
			callback(2, jsnes.Controller.BUTTON_SELECT); break;
		case 13: // Return
			callback(1, jsnes.Controller.BUTTON_START);
			callback(2, jsnes.Controller.BUTTON_START); break;
			
		default: break;
	}
}

function nes_init(canvas_id) {
	var canvas = document.getElementById(canvas_id);
	canvas_ctx = canvas.getContext("2d");
	image = canvas_ctx.getImageData(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
	
	canvas_ctx.fillStyle = "black";
	canvas_ctx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
	
	// Allocate framebuffer array.
	var buffer = new ArrayBuffer(image.data.length);
	framebuffer_u8 = new Uint8ClampedArray(buffer);
	framebuffer_u32 = new Uint32Array(buffer);
	
	// Setup audio.
	var audio_ctx = new window.AudioContext();
	var script_processor = audio_ctx.createScriptProcessor(AUDIO_BUFFERING, 0, 2);
	script_processor.onaudioprocess = audio_callback;
	script_processor.connect(audio_ctx.destination);
	
	volume = document.getElementById("volume").value;
	document.getElementById ("volume").addEventListener ("input", function () {
		volume = document.getElementById("volume").value;
	});
}

function nes_boot(rom_data){
	nes.loadROM(rom_data);
	window.requestAnimationFrame(onAnimationFrame);
}

function nes_load_data(canvas_id, rom_data) {
	nes_init(canvas_id);
	nes_boot(rom_data);
}

function nes_load_url(canvas_id, path) {
	nes_init(canvas_id);
	
	var req = new XMLHttpRequest();
	req.open("GET", path);
	req.overrideMimeType("text/plain; charset=x-user-defined");
	req.onerror = () => console.log(`Error loading ${path}: ${req.statusText}`);
	
	req.onload = function() {
		if (this.status === 200) {
			nes_boot(this.responseText);
		} else if (this.status === 0) {
			// Aborted, so ignore error
		} else {
			req.onerror();
		}
	};
	
	req.send();
}

document.addEventListener('keydown', (event) => {keyboard(nes.buttonDown, event)});
document.addEventListener('keyup', (event) => {keyboard(nes.buttonUp, event)});