function audio_trimmed = removeInitialSilence(audio, ts, threshold)
%funcao para remover o silencio inicial dos sinais

  h = 0.005;
  step_length = max(1, round(h * ts));

  if isempty(audio)
    audio_trimmed = audio;
    return;
  end

  nFrames = max(1, floor(length(audio) / step_length));
  energy = zeros(nFrames, 1);

  %divide em "frames" e calcula a energia de cada frame
  for j = 1:nFrames
    idxStart = (j - 1) * step_length + 1;
    idxEnd = min(j * step_length, length(audio));
    frame = audio(idxStart:idxEnd, :);
    energy(j) = sum(frame(:) .^ 2);
  end

  maxEnergy = max(energy);
  if maxEnergy <= 0
    audio_trimmed = audio;
    return;
  end

  energy = energy / maxEnergy;

  startFrame = find(energy > threshold, 1, 'first');
  if isempty(startFrame)
    audio_trimmed = audio;
    return;
  end

  start_index = (startFrame - 1) * step_length + 1;
  start_index = min(max(1, start_index), length(audio));

  audio_trimmed = audio(start_index:end, :);
end
