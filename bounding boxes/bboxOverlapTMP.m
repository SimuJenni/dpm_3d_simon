function label=bboxOverlapTMP(bbox1, bbox2,overlap)
    % intesection with bbox
    label=0;
    xx1 = max(bbox1(1), bbox2(1));
    yy1 = max(bbox1(2), bbox2(2));
    xx2 = min(bbox1(3), bbox2(3));
    yy2 = min(bbox1(4), bbox2(4));
    w = (xx2-xx1+1);
    h = (yy2-yy1+1);
    if w > 0 && h > 0
      % check overlap with bbox
      inter = w*h;
      a = (bbox1(3)-bbox1(1)+1) * (bbox1(4)-bbox1(2)+1);
      b = (bbox2(3)-bbox2(1)+1) * (bbox2(4)-bbox2(2)+1);
      o = inter / (a+b-inter);
      if (o >= overlap)
          label=1;
      end
    end
end